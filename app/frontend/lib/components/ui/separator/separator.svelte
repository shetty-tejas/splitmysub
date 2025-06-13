<script>
  import { cn } from "$lib/utils.js";

  export let orientation = "horizontal";
  export let decorative = true;
  export let className = "";
</script>

<div
  role={decorative ? "none" : "separator"}
  aria-orientation={orientation}
  class={cn(
    "shrink-0 bg-border",
    orientation === "horizontal" ? "h-[1px] w-full" : "h-full w-[1px]",
    className,
  )}
  {...$$restProps}
></div>
