<script>
  import { cn } from "$lib/utils.js";

  let {
    class: className = "",
    value = $bindable(""),
    rows = 3,
    ...restProps
  } = $props();
</script>

<textarea
  bind:value
  {rows}
  class={cn(
    "border-input placeholder:text-muted-foreground focus-visible:border-ring focus-visible:ring-ring/50 focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive flex min-h-[60px] w-full rounded-md border bg-transparent px-3 py-2 text-base shadow-sm transition-[color,box-shadow] focus-visible:outline-none disabled:cursor-not-allowed disabled:opacity-50 resize-y md:text-sm",
    className,
  )}
  {...restProps}
></textarea>
