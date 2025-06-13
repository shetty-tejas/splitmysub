<script>
  import { page } from "@inertiajs/svelte";
  import { router } from "@inertiajs/svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Button } from "$lib/components/ui/button";
  import { AlertTriangle, Clock, Home } from "lucide-svelte";

  export const invitation = null;
  export const project = null;

  function goHome() {
    router.get("/");
  }

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  }
</script>

<svelte:head>
  <title>Invitation Expired - SplitSub</title>
</svelte:head>

<div class="min-h-screen flex items-center justify-center p-4">
  <div class="text-center">
    <h1 class="text-3xl font-bold text-gray-900 mb-4">Invitation Expired</h1>
    <p class="text-gray-600">This invitation link is no longer valid</p>
  </div>
</div>
