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
    viewBox="0 0 32 32"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    class="flex-shrink-0"
  >
    <!-- Split icon representing subscription sharing -->
    <rect
      x="4"
      y="6"
      width="24"
      height="4"
      rx="2"
      fill="currentColor"
      opacity="0.8"
    />
    <rect x="4" y="14" width="10" height="4" rx="2" fill="currentColor" />
    <rect x="18" y="14" width="10" height="4" rx="2" fill="currentColor" />
    <rect
      x="4"
      y="22"
      width="7"
      height="4"
      rx="2"
      fill="currentColor"
      opacity="0.6"
    />
    <rect
      x="13"
      y="22"
      width="7"
      height="4"
      rx="2"
      fill="currentColor"
      opacity="0.6"
    />
    <rect
      x="22"
      y="22"
      width="6"
      height="4"
      rx="2"
      fill="currentColor"
      opacity="0.6"
    />

    <!-- Connection dots -->
    <circle cx="16" cy="8" r="1.5" fill="currentColor" />
    <circle cx="9" cy="16" r="1.5" fill="currentColor" />
    <circle cx="23" cy="16" r="1.5" fill="currentColor" />
  </svg>
  <span class="flex-shrink-0">Splitsub</span>
</div>
