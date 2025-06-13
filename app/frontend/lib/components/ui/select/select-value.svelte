<script>
  export let placeholder = "";
</script>

<span class="pointer-events-none">
  <slot />
  {#if !$$slots.default && placeholder}
    <span class="text-muted-foreground">{placeholder}</span>
  {/if}
</span>
