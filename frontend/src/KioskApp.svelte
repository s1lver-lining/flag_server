<script>
  import { onMount, onDestroy } from 'svelte';
  import { io } from 'socket.io-client';
  import Kiosk from './components/Kiosk.svelte';
  
  // Use relative URLs - backend serves frontend
  const API_URL = '';
  
  let socket;
  let scoreboard = [];
  
  async function loadScoreboard() {
    try {
      const response = await fetch(`${API_URL}/api/scoreboard`);
      scoreboard = await response.json();
    } catch (error) {
      console.error('Error loading scoreboard:', error);
    }
  }
  
  onMount(async () => {
    await loadScoreboard();
    
    // Setup WebSocket connection for live updates
    socket = io(API_URL);
    
    socket.on('connect', () => {
      console.log('Kiosk connected to server');
    });
    
    socket.on('scoreboard_update', async () => {
      await loadScoreboard();
    });
    
    socket.on('disconnect', () => {
      console.log('Kiosk disconnected from server');
    });
  });
  
  onDestroy(() => {
    if (socket) {
      socket.disconnect();
    }
  });
</script>

<Kiosk {scoreboard} />