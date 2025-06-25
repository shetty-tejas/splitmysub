<script>
  import { cn } from "$lib/utils.js";

  let { class: className = "", ...props } = $props();
</script>

<div
  class={cn(
    "flex items-center gap-2 font-bold text-lg whitespace-nowrap",
    className,
  )}
  {...props}
>
  <svg
    width="28"
    height="28"
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    stroke="currentColor"
    stroke-width="2"
    stroke-linecap="round"
    stroke-linejoin="round"
    class="flex-shrink-0"
  >
    <path d="M16 3h5v5" />
    <path d="M8 3H3v5" />
    <path d="M12 22v-8.3a4 4 0 0 0-1.172-2.872L3 3" />
    <path d="m15 9 6-6" />
  </svg>
  <span class="flex-shrink-0">SplitMySub</span>
</div>
