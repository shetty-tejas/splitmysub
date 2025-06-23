<script>
  import { page } from "@inertiajs/svelte";
  import Navbar from "../lib/components/navbar.svelte";
  import { Button } from "../lib/components/ui/button";
  import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
  } from "../lib/components/ui/card";
  import { Badge } from "../lib/components/ui/badge";

  export let title = "Admin Panel";
</script>

<svelte:head>
  <title>{title} - SplitSub Admin</title>
</svelte:head>

<div class="min-h-screen bg-gray-50">
  <!-- Admin Header -->
  <div class="bg-red-600 text-white shadow-sm">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between h-16">
        <div class="flex items-center space-x-4">
          <h1 class="text-xl font-bold">🛠️ SplitSub Admin</h1>
          <Badge variant="secondary" class="bg-red-500 text-white">
            Administrator Panel
          </Badge>
        </div>
        <div class="flex items-center space-x-4">
          <span class="text-sm opacity-75">
            Environment: {import.meta.env.NODE_ENV || "development"}
          </span>
          <Button
            href="/"
            variant="outline"
            size="sm"
            class="text-red-600 border-white hover:bg-red-50"
          >
            ← Back to App
          </Button>
        </div>
      </div>
    </div>
  </div>

  <!-- Admin Navigation -->
  <div class="bg-white shadow-sm border-b">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <nav class="flex space-x-8 py-4">
        <a
          href="/admin/billing_configuration"
          class="text-gray-600 hover:text-gray-900 px-3 py-2 text-sm font-medium border-b-2
                 {$page.url.startsWith('/admin/billing_configuration')
            ? 'border-red-500 text-red-600'
            : 'border-transparent'}"
        >
          💰 Billing Configuration
        </a>
        <!-- Future admin sections can be added here -->
        <span
          class="text-gray-400 px-3 py-2 text-sm font-medium border-b-2 border-transparent cursor-not-allowed"
        >
          📊 System Analytics (Coming Soon)
        </a>
        <span
          class="text-gray-400 px-3 py-2 text-sm font-medium border-b-2 border-transparent cursor-not-allowed"
        >
          👥 User Management (Coming Soon)
        </a>
      </nav>
    </div>
  </div>

  <!-- Main Content -->
  <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <slot />
  </main>

  <!-- Admin Footer -->
  <footer class="bg-gray-100 border-t mt-12">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
      <div class="text-center text-sm text-gray-500">
        <p>
          SplitSub Admin Panel |
          <strong class="text-red-600">Use with caution</strong> - Changes affect
          all users
        </p>
      </div>
    </div>
  </footer>
</div>

<style>
  :global(.admin-panel) {
    background: linear-gradient(135deg, #fee2e2 0%, #fecaca 100%);
  }
</style>
