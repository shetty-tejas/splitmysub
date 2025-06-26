<script>
  let {
    children,
    columns = [],
    data = [],
    mobileStackBreakpoint = "md",
  } = $props();
</script>

<!-- Desktop Table -->
<div class="hidden {mobileStackBreakpoint}:block overflow-x-auto">
  <table class="min-w-full divide-y divide-gray-200">
    {#if columns.length > 0}
      <thead class="bg-gray-50">
        <tr>
          {#each columns as column}
            <th
              class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
            >
              {column.label}
            </th>
          {/each}
        </tr>
      </thead>
    {/if}
    <tbody class="bg-white divide-y divide-gray-200">
      {#each data as item, index}
        <tr class="hover:bg-gray-50">
          {#each columns as column}
            <td class="px-6 py-4 whitespace-nowrap">
              {@render children(item, column, index)}
            </td>
          {/each}
        </tr>
      {/each}
    </tbody>
  </table>
</div>

<!-- Mobile Stack -->
<div class="{mobileStackBreakpoint}:hidden space-y-4">
  {#each data as item, index}
    <div class="bg-white p-4 rounded-lg border border-gray-200 shadow-sm">
      {#each columns as column}
        <div
          class="flex justify-between py-2 border-b border-gray-100 last:border-b-0"
        >
          <dt class="text-sm font-medium text-gray-600">{column.label}</dt>
          <dd class="text-sm text-gray-900 text-right">
            {@render children(item, column, index)}
          </dd>
        </div>
      {/each}
    </div>
  {/each}
</div>
