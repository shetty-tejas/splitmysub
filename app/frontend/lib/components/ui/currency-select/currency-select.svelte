<script>
  import { cn } from "$lib/utils.js";
  import {
    getCurrencySymbol,
    getDefaultCurrency,
  } from "../../../currency-utils.js";

  export let value = "USD";
  export let currencyOptions = [];
  export let placeholder = "Select currency";
  export let onValueChange = null;
  export let className = "";
  export let disabled = false;

  // Auto-detect default currency if no value provided
  if (!value) {
    value = getDefaultCurrency();
  }

  function handleChange(event) {
    value = event.target.value;
    if (onValueChange) {
      onValueChange(value);
    }
  }
</script>

<select
  bind:value
  on:change={handleChange}
  {disabled}
  class={cn(
    "flex h-9 w-full items-center justify-between whitespace-nowrap rounded-md border border-input bg-transparent px-3 py-2 text-sm shadow-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-1 focus:ring-ring disabled:cursor-not-allowed disabled:opacity-50",
    className,
  )}
  {...$$restProps}
>
  {#if placeholder && !value}
    <option value="" disabled>{placeholder}</option>
  {/if}
  {#each currencyOptions as [label, code]}
    <option value={code}>
      {getCurrencySymbol(code)}
      {code} - {label.split(" (")[0]}
    </option>
  {/each}
</select>
