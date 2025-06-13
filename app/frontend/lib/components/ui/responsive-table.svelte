<script>
  let { children, headers = [], mobileStackBreakpoint = "md" } = $props();
</script>

<!-- Desktop Table -->
<div class="hidden {mobileStackBreakpoint}:block overflow-x-auto">
  <table class="min-w-full divide-y divide-gray-200">
    {#if headers.length > 0}
      <thead class="bg-gray-50">
        <tr>
          {#each headers as header}
            <th
              class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
            >
              {header}
            </th>
          {/each}
        </tr>
      </thead>
    {/if}
    <tbody class="bg-white divide-y divide-gray-200">
      {@render children()}
    </tbody>
  </table>
</div>

<!-- Mobile Stack -->
<div class="{mobileStackBreakpoint}:hidden space-y-4">
  {@render children()}
</div>
