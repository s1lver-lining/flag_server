<script>
  export let challenges = [];
  
  const categoryColors = {
    'Easy': 'bg-green-600',
    'Crypto': 'bg-purple-600',
    'Web': 'bg-blue-600',
    'Misc': 'bg-yellow-600',
    'Pwn': 'bg-red-600',
    'Reverse': 'bg-pink-600',
  };
  
  function getCategoryColor(category) {
    return categoryColors[category] || 'bg-gray-600';
  }
</script>

<div class="max-w-6xl mx-auto">
  <h2 class="text-3xl font-bold mb-6 text-cyan-400">Available Challenges</h2>
  
  <!-- Info Card -->
  <div class="bg-gradient-to-r from-cyan-900/50 to-blue-900/50 border border-cyan-500/50 rounded-lg p-6 mb-8 shadow-lg">
    <div>
      <h3 class="text-xl font-bold text-white mb-2 flex items-center gap-2">
        <span class="text-2xl">📦</span>
        <span>Challenge Files</span>
      </h3>
      <p class="text-slate-300 mb-4">
        All challenges share the same binary and source code. The only difference is the bytecode (.fvm file).<br>
        Usage: <code>./fvm bytecode.fvm FLAG{'{'}example_flag{'}'}</code><br>
      </p>
      <a 
        href="/api/download-challenges"
        download
        class="inline-flex items-center gap-2 bg-cyan-600 hover:bg-cyan-700 text-white font-semibold py-2 px-4 rounded-lg transition-all transform hover:scale-105 shadow-md"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd" />
        </svg>
        Download All Challenges
      </a>
    </div>
  </div>
  
  {#if challenges.length === 0}
    <div class="bg-slate-800 rounded-lg p-8 text-center">
      <p class="text-slate-400 text-lg">No challenges available yet.</p>
    </div>
  {:else}
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {#each challenges as challenge}
        <div class="bg-slate-800 rounded-lg shadow-lg border border-slate-700 hover:border-cyan-500 transition-all p-6 hover:transform hover:scale-105">
          <div class="flex items-start justify-between mb-4">
            <h3 class="text-xl font-bold text-white">{challenge.title}</h3>
            <span class="px-3 py-1 rounded-full text-xs font-semibold text-white {getCategoryColor(challenge.category)}">
              {challenge.category}
            </span>
          </div>
          
          <p class="text-slate-300 mb-4 leading-relaxed">
            {challenge.description}
          </p>
          
          <div class="flex items-center justify-between mt-4 pt-4 border-t border-slate-700">
            <span class="text-cyan-400 font-bold text-lg">{challenge.points} pts</span>
            <span class="text-slate-500 text-sm">Challenge #{challenge.id}</span>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>
