<script>
  import { page } from "@inertiajs/svelte";
  import { Toaster } from "$lib/components/ui/sonner/index.js";
  import Navbar from "$lib/components/navbar.svelte"; // Adjust the path as necessary

  let { children } = $props();
</script>

<div class="bg-bg">
  <main>{@render children()}</main>
  <Toaster />
</div>
