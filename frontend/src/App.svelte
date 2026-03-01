<script>
  import { onMount, onDestroy } from 'svelte';
  import { io } from 'socket.io-client';
  import Challenges from './components/Challenges.svelte';
  import Scoreboard from './components/Scoreboard.svelte';
  import FlagSubmission from './components/FlagSubmission.svelte';
  
  // Use relative URLs - backend serves frontend
  const API_URL = '';
  
  let socket;
  let challenges = [];
  let scoreboard = [];
  let activeTab = 'challenges';
  let notification = null;
  
  async function loadChallenges() {
    try {
      const response = await fetch(`${API_URL}/api/challenges`);
      challenges = await response.json();
    } catch (error) {
      console.error('Error loading challenges:', error);
    }
  }
  
  async function loadScoreboard() {
    try {
      const response = await fetch(`${API_URL}/api/scoreboard`);
      scoreboard = await response.json();
    } catch (error) {
      console.error('Error loading scoreboard:', error);
    }
  }
  
  function showNotification(message, type = 'info') {
    notification = { message, type };
    setTimeout(() => {
      notification = null;
    }, 5000);
  }
  
  async function handleSubmit(event) {
    const { username, flag } = event.detail;
    
    try {
      const response = await fetch(`${API_URL}/api/submit`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, flag }),
      });
      
      const data = await response.json();
      
      if (data.success) {
        showNotification(data.message, 'success');
        await loadScoreboard();
      } else {
        showNotification(data.message, 'error');
      }
    } catch (error) {
      showNotification('Error submitting flag', 'error');
      console.error('Error:', error);
    }
  }
  
  onMount(async () => {
    await loadChallenges();
    await loadScoreboard();
    
    // Setup WebSocket connection
    socket = io(API_URL);
    
    socket.on('connect', () => {
      console.log('Connected to server');
    });
    
    socket.on('scoreboard_update', async (data) => {
      console.log('Scoreboard update:', data);
      await loadScoreboard();
      
      if (activeTab === 'scoreboard') {
        showNotification(
          `${data.username} solved ${data.challenge}!`,
          'info'
        );
      }
    });
    
    socket.on('disconnect', () => {
      console.log('Disconnected from server');
    });
  });
  
  onDestroy(() => {
    if (socket) {
      socket.disconnect();
    }
  });
</script>

<main class="min-h-screen bg-slate-900">
  <!-- Header -->
  <header class="bg-slate-800 border-b border-slate-700 shadow-lg">
    <div class="container mx-auto px-4 py-6">
      <h1 class="text-4xl font-bold text-center bg-gradient-to-r from-cyan-400 to-blue-500 bg-clip-text text-transparent">
        🚩 Flag Verification Platform
      </h1>
      <p class="text-center text-slate-400 mt-2">Flag verification machine verification platform</p>
    </div>
  </header>

  <!-- Notification -->
  {#if notification}
    <div class="fixed top-4 right-4 z-50 animate-slide-in">
      <div class="rounded-lg shadow-lg px-6 py-4 max-w-md {
        notification.type === 'success' ? 'bg-green-600' :
        notification.type === 'error' ? 'bg-red-600' :
        'bg-blue-600'
      }">
        <p class="text-white font-medium">{notification.message}</p>
      </div>
    </div>
  {/if}

  <!-- Navigation Tabs -->
  <div class="container mx-auto px-4 mt-8">
    <div class="flex space-x-2 border-b border-slate-700">
      <button
        class="px-6 py-3 font-semibold transition-all {
          activeTab === 'challenges'
            ? 'text-cyan-400 border-b-2 border-cyan-400'
            : 'text-slate-400 hover:text-slate-300'
        }"
        on:click={() => activeTab = 'challenges'}
      >
        Challenges
      </button>
      <button
        class="px-6 py-3 font-semibold transition-all {
          activeTab === 'submit'
            ? 'text-cyan-400 border-b-2 border-cyan-400'
            : 'text-slate-400 hover:text-slate-300'
        }"
        on:click={() => activeTab = 'submit'}
      >
        Submit Flag
      </button>
      <button
        class="px-6 py-3 font-semibold transition-all {
          activeTab === 'scoreboard'
            ? 'text-cyan-400 border-b-2 border-cyan-400'
            : 'text-slate-400 hover:text-slate-300'
        }"
        on:click={() => activeTab = 'scoreboard'}
      >
        Scoreboard
      </button>
    </div>
  </div>

  <!-- Content -->
  <div class="container mx-auto px-4 py-8">
    {#if activeTab === 'challenges'}
      <Challenges {challenges} />
    {:else if activeTab === 'submit'}
      <FlagSubmission on:submit={handleSubmit} />
    {:else if activeTab === 'scoreboard'}
      <Scoreboard {scoreboard} />
    {/if}
  </div>
</main>

<style>
  @keyframes slide-in {
    from {
      transform: translateX(100%);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }
  
  .animate-slide-in {
    animation: slide-in 0.3s ease-out;
  }
</style>
