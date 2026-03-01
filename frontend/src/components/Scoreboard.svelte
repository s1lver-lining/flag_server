<script>
  export let scoreboard = [];
  
  function getMedalEmoji(rank) {
    switch(rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return `#${rank}`;
    }
  }
  
  function getRankColor(rank) {
    switch(rank) {
      case 1: return 'text-yellow-400';
      case 2: return 'text-gray-300';
      case 3: return 'text-amber-600';
      default: return 'text-slate-400';
    }
  }
</script>

<div class="max-w-4xl mx-auto">
  <h2 class="text-3xl font-bold mb-6 text-cyan-400">🏆 Scoreboard</h2>
  
  {#if scoreboard.length === 0}
    <div class="bg-slate-800 rounded-lg p-8 text-center border border-slate-700">
      <p class="text-slate-400 text-lg">No scores yet. Be the first to submit a flag!</p>
    </div>
  {:else}
    <div class="bg-slate-800 rounded-lg shadow-xl border border-slate-700 overflow-hidden">
      <!-- Header -->
      <div class="bg-slate-900 px-6 py-4 border-b border-slate-700">
        <div class="grid grid-cols-12 gap-4 font-semibold text-slate-300">
          <div class="col-span-2 text-center">Rank</div>
          <div class="col-span-7">Username</div>
          <div class="col-span-3 text-right">Score</div>
        </div>
      </div>
      
      <!-- Scoreboard entries -->
      <div class="divide-y divide-slate-700">
        {#each scoreboard as entry, index}
          <div 
            class="px-6 py-4 hover:bg-slate-700 transition-colors {
              index < 3 ? 'bg-slate-750' : ''
            }"
          >
            <div class="grid grid-cols-12 gap-4 items-center">
              <div class="col-span-2 text-center">
                <span class="text-2xl font-bold {getRankColor(index + 1)}">
                  {getMedalEmoji(index + 1)}
                </span>
              </div>
              <div class="col-span-7">
                <span class="text-lg font-semibold text-white">
                  {entry.username}
                </span>
              </div>
              <div class="col-span-3 text-right">
                <span class="text-xl font-bold text-cyan-400">
                  {entry.score}
                </span>
                <span class="text-slate-400 text-sm ml-1">pts</span>
              </div>
            </div>
          </div>
        {/each}
      </div>
    </div>
    
    <div class="mt-6 text-center text-slate-400 text-sm">
      <p>The scoreboard is not representative of someone's actual skill.</p>
    </div>
  {/if}
</div>
