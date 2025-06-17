<script>
  // grab page props from inertia
  import { page, Link, router } from "@inertiajs/svelte";
  import Logo from "$lib/components/logo.svelte";
  import { Menu, LogOut, BarChart3, X, User } from "lucide-svelte";
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu/index.js";
  import { Button } from "$lib/components/ui/button/index.js";
  import { Separator } from "$lib/components/ui/separator/index.js";
  import {
    rootPath,
    loginPath,
    signupPath,
    logoutPath,
    dashboardPath,
  } from "@/routes";

  function handleLogout(event) {
    event.preventDefault();
    router.delete(logoutPath());
  }

  const links = [
    { href: "#features", label: "Features" },
    { href: "#how-it-works", label: "How it Works" },
    { href: "#pricing", label: "Pricing" },
  ];

  const currentUser = $derived($page.props?.user);
  let mobileMenuOpen = $state(false);

  function toggleMobileMenu() {
    mobileMenuOpen = !mobileMenuOpen;
  }

  function closeMobileMenu() {
    mobileMenuOpen = false;
  }

  // Get user initials for avatar
  const getUserInitials = (user) => {
    if (!user?.email_address) return "U";
    return user.email_address
      .split("@")[0]
      .split(".")
      .map((part) => part.charAt(0).toUpperCase())
      .join("")
      .slice(0, 2);
  };
</script>

<nav
  class="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60"
>
  <div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8">
    <div class="flex h-16 items-center justify-between">
      <!-- Logo -->
      <div class="flex items-center">
        <Link
          href={currentUser ? dashboardPath() : rootPath()}
          class="flex items-center space-x-2"
        >
          <Logo class="text-primary" />
        </Link>
      </div>

      <!-- Desktop Navigation -->
      <nav class="hidden items-center space-x-6 md:flex">
        {#if !currentUser}
          {#each links as link}
            <Link
              href={link.href}
              class="text-sm font-medium text-muted-foreground transition-colors hover:text-foreground"
            >
              {link.label}
            </Link>
          {/each}
        {/if}
      </nav>

      <div class="flex items-center space-x-4">
        <!-- User Menu -->
        <div class="hidden md:flex">
          {#if currentUser}
            <DropdownMenu.Root>
              <DropdownMenu.Trigger
                class="inline-flex h-9 w-9 items-center justify-center rounded-full bg-primary text-primary-foreground text-sm font-medium transition-colors hover:bg-primary/90 focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 cursor-pointer"
              >
                {getUserInitials(currentUser)}
                <span class="sr-only">Open user menu</span>
              </DropdownMenu.Trigger>
              <DropdownMenu.Content class="w-64" align="end">
                <DropdownMenu.Label class="font-normal">
                  <div class="flex flex-col space-y-1">
                    <p class="text-sm font-medium leading-none">
                      {currentUser.email_address.split("@")[0]}
                    </p>
                    <p class="text-xs leading-none text-muted-foreground">
                      {currentUser.email_address}
                    </p>
                  </div>
                </DropdownMenu.Label>
                <DropdownMenu.Separator />
                <DropdownMenu.Group>
                  <DropdownMenu.Item
                    onclick={() => router.visit("/dashboard")}
                    class="cursor-pointer"
                  >
                    <BarChart3 class="mr-2 h-4 w-4" />
                    <span>Dashboard</span>
                  </DropdownMenu.Item>
                  <DropdownMenu.Item
                    onclick={() => router.visit("/profile")}
                    class="cursor-pointer"
                  >
                    <User class="mr-2 h-4 w-4" />
                    <span>Profile</span>
                  </DropdownMenu.Item>
                </DropdownMenu.Group>
                <DropdownMenu.Separator />
                <DropdownMenu.Item
                  onclick={handleLogout}
                  class="text-red-600 focus:text-red-600 cursor-pointer"
                >
                  <LogOut class="mr-2 h-4 w-4" />
                  <span>Log out</span>
                </DropdownMenu.Item>
              </DropdownMenu.Content>
            </DropdownMenu.Root>
          {:else}
            <div class="flex items-center space-x-2">
              <Link href={loginPath()}>
                <Button variant="ghost" size="sm" class="text-sm font-medium">
                  Log in
                </Button>
              </Link>
              <Link href={signupPath()}>
                <Button size="sm" class="text-sm font-medium">Sign up</Button>
              </Link>
            </div>
          {/if}
        </div>

        <!-- Mobile Menu Button -->
        <div class="flex md:hidden">
          <Button
            variant="ghost"
            size="sm"
            class="h-9 w-9 px-0"
            onclick={toggleMobileMenu}
          >
            {#if mobileMenuOpen}
              <X class="h-5 w-5" />
            {:else}
              <Menu class="h-5 w-5" />
            {/if}
            <span class="sr-only">Toggle menu</span>
          </Button>
        </div>
      </div>
    </div>
  </div>

  <!-- Mobile Menu -->
  {#if mobileMenuOpen}
    <div class="border-t bg-background md:hidden">
      <div class="mx-auto max-w-7xl space-y-4 px-4 py-4 sm:px-6 lg:px-8">
        {#if currentUser}
          <!-- User Info -->
          <Link href="/profile" onclick={closeMobileMenu}>
            <div
              class="mb-4 rounded-lg border bg-card p-4 transition-colors hover:bg-accent cursor-pointer"
            >
              <div class="flex items-center space-x-3">
                <div
                  class="flex h-10 w-10 items-center justify-center rounded-full bg-primary text-primary-foreground font-medium"
                >
                  {getUserInitials(currentUser)}
                </div>
                <div class="flex-1 min-w-0">
                  <p class="text-sm font-medium truncate">
                    {currentUser.email_address.split("@")[0]}
                  </p>
                  <p class="text-xs text-muted-foreground truncate">
                    {currentUser.email_address}
                  </p>
                </div>
              </div>
            </div>
          </Link>

          <!-- Navigation Links -->
          <nav class="space-y-1">
            <Link
              href="/dashboard"
              onclick={closeMobileMenu}
              class="flex items-center space-x-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground"
            >
              <BarChart3 class="h-5 w-5" />
              <span>Dashboard</span>
            </Link>
            <Link
              href="/profile"
              onclick={closeMobileMenu}
              class="flex items-center space-x-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground"
            >
              <User class="h-5 w-5" />
              <span>Profile</span>
            </Link>
          </nav>

          <Separator />

          <!-- Logout Button -->
          <button
            type="button"
            onclick={() => {
              handleLogout(event);
              closeMobileMenu();
            }}
            class="flex w-full items-center space-x-3 rounded-lg px-3 py-2 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 hover:text-red-700"
          >
            <LogOut class="h-5 w-5" />
            <span>Log out</span>
          </button>
        {:else}
          <!-- Guest Navigation -->
          <nav class="space-y-1">
            {#each links as link}
              <Link
                href={link.href}
                onclick={closeMobileMenu}
                class="block rounded-lg px-3 py-2 text-sm font-medium transition-colors hover:bg-accent hover:text-accent-foreground"
              >
                {link.label}
              </Link>
            {/each}
          </nav>

          <Separator />

          <!-- Auth Buttons -->
          <div class="space-y-2">
            <Link href={loginPath()} onclick={closeMobileMenu} class="block">
              <Button variant="outline" class="w-full justify-center">
                Log in
              </Button>
            </Link>
            <Link href={signupPath()} onclick={closeMobileMenu} class="block">
              <Button class="w-full justify-center">Sign up</Button>
            </Link>
          </div>
        {/if}
      </div>
    </div>
  {/if}
</nav>
