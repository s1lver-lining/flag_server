<script>
  import { createEventDispatcher } from 'svelte';
  
  const dispatch = createEventDispatcher();
  
  let username = '';
  let flag = '';
  let isSubmitting = false;
  
  async function handleSubmit(event) {
    event.preventDefault();
    
    if (!username.trim() || !flag.trim()) {
      return;
    }
    
    // Limit username to 20 characters
    if (username.trim().length > 20) {
      alert('Username must be 20 characters or less');
      return;
    }
    
    isSubmitting = true;
    
    dispatch('submit', {
      username: username.trim(),
      flag: flag.trim()
    });
    
    // Clear flag but keep username
    flag = '';
    
    setTimeout(() => {
      isSubmitting = false;
    }, 1000);
  }
</script>

<div class="max-w-2xl mx-auto">
  <div class="bg-slate-800 rounded-lg shadow-xl border border-slate-700 p-8">
    <h2 class="text-3xl font-bold mb-6 text-cyan-400">Submit Flag</h2>
    
    <form on:submit={handleSubmit} class="space-y-6">
      <div>
        <label for="username" class="block text-sm font-medium text-slate-300 mb-2">
          Username
        </label>
        <input
          id="username"
          type="text"
          bind:value={username}
          placeholder="Enter your username"
          required
          maxlength="20"
          class="w-full px-4 py-3 bg-slate-900 border border-slate-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-transparent text-white placeholder-slate-500 transition-all"
        />
        <p class="mt-1 text-xs text-slate-400">
          Max 20 characters
        </p>
      </div>
      
      <div>
        <label for="flag" class="block text-sm font-medium text-slate-300 mb-2">
          Flag
        </label>
        <input
          id="flag"
          type="text"
          bind:value={flag}
          placeholder="FLAG&#123;...&#125;"
          required
          class="w-full px-4 py-3 bg-slate-900 border border-slate-600 rounded-lg focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-transparent text-white placeholder-slate-500 font-mono transition-all"
        />
        <p class="mt-2 text-sm text-slate-400">
          Enter the flag you found in the format: FLAG{'{'}...{'}'}
        </p>
      </div>
      
      <button
        type="submit"
        disabled={isSubmitting || !username.trim() || !flag.trim()}
        class="w-full bg-gradient-to-r from-cyan-500 to-blue-600 hover:from-cyan-600 hover:to-blue-700 text-white font-bold py-3 px-6 rounded-lg transition-all transform hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:scale-100 shadow-lg"
      >
        {isSubmitting ? 'Submitting...' : 'Submit Flag'}
      </button>
    </form>
    
    <div class="mt-8 p-4 bg-slate-900 rounded-lg border border-slate-700">
      <h3 class="text-sm font-semibold text-slate-300 mb-2">💡 Tips:</h3>
      <ul class="text-sm text-slate-400 space-y-1 list-disc list-inside">
        <li>Make sure your flag format is correct (usually FLAG{'{'}...{'}'})</li>
        <li>Flags are case-sensitive</li>
        <li>The score given by a flag is static, meaning it won't change over time.</li>
      </ul>
    </div>
  </div>
</div>
