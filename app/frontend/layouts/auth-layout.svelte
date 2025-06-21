<script>
  import { page } from "@inertiajs/svelte";
  import { Toaster } from "$lib/components/ui/sonner/index.js";
  import { toast } from "svelte-sonner";
  import Navbar from "$lib/components/navbar.svelte"; // Adjust the path as necessary

  let { children } = $props();

  let lastFlashId = $state(null);

  $effect(() => {
    let flash = $page.props?.flash || {};

    // Create a unique ID for this flash message to prevent duplicates
    const flashId = JSON.stringify(flash);

    if (flashId !== lastFlashId && flashId !== "{}") {
      flash.notice && toast.success(flash.notice);
      flash.alert && toast.error(flash.alert);
      lastFlashId = flashId;
    }
  });
</script>

<div class="bg-bg">
  <main>{@render children()}</main>
  <Toaster />
</div>
