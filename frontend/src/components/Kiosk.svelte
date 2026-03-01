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
      case 1: return 'text-yellow-500';
      case 2: return 'text-gray-400';
      case 3: return 'text-amber-600';
      default: return 'text-gray-600';
    }
  }
</script>

<!-- Portrait A4 layout (210mm x 297mm) -->
<div class="kiosk-container bg-gray-100 min-h-screen p-8">
  <div class="max-w-2xl mx-auto">
    <!-- Header Section -->
    <div class="text-center mb-8">
      
      <div class="flex items-center justify-center gap-8 mb-8">
        <div class="flex-1">
          <h1 class="text-6xl font-bold text-gray-800 mb-4">
            Bad at reversing?
          </h1>
          <div class="flex-1">
            <p class="text-2xl text-gray-700">
              Try this increasing-difficulty CTF challenge
            </p>
          </div>
        </div>
        
        <!-- QR Code Placeholder -->
        <div class="flex-shrink-0">
          <div class="w-40 h-40 bg-white border-4 border-gray-300 rounded-lg flex items-center justify-center shadow-md">
            <div class="text-center">
              <div class="text-4xl mb-2">📱</div>
              <div class="text-xs text-gray-500">QR Code</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Scoreboard Section -->
    <div class="mt-12">
      
      {#if scoreboard.length === 0}
        <div class="bg-white rounded-lg p-8 text-center border border-gray-300 shadow">
          <p class="text-gray-600 text-xl">No scores yet. Be the first to submit a flag!</p>
        </div>
      {:else}
        <div class="bg-white rounded-lg shadow-lg border border-gray-300 overflow-hidden">
          <!-- Header -->
          <div class="bg-gray-50 px-6 py-4 border-b border-gray-300">
            <div class="grid grid-cols-12 gap-4 font-semibold text-gray-700 text-lg">
              <div class="col-span-2 text-center">Rank</div>
              <div class="col-span-7">Username</div>
              <div class="col-span-3 text-right">Score</div>
            </div>
          </div>
          
          <!-- Scoreboard entries -->
          <div class="divide-y divide-gray-200">
            {#each scoreboard as entry, index}
              <div 
                class="px-6 py-5 {
                  index < 3 ? 'bg-gray-50' : 'bg-white'
                } hover:bg-gray-100 transition-colors"
              >
                <div class="grid grid-cols-12 gap-4 items-center">
                  <div class="col-span-2 text-center">
                    <span class="text-3xl font-bold {getRankColor(index + 1)}">
                      {getMedalEmoji(index + 1)}
                    </span>
                  </div>
                  <div class="col-span-7">
                    <span class="text-xl font-semibold text-gray-800">
                      {entry.username}
                    </span>
                  </div>
                  <div class="col-span-3 text-right">
                    <span class="text-2xl font-bold text-gray-800">
                      {entry.score}
                    </span>
                    <span class="text-gray-500 text-base ml-1">pts</span>
                  </div>
                </div>
              </div>
            {/each}
          </div>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .kiosk-container {
    /* A4 portrait dimensions: 210mm x 297mm at 96 DPI */
    width: 210mm;
    min-height: 297mm;
    margin: 0 auto;
  }
  
  @media print {
    .kiosk-container {
      width: 210mm;
      height: 297mm;
      page-break-after: always;
    }
  }
</style>
