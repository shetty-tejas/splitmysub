<script>
  // grab page props from inertia
  import { page, Link, router } from "@inertiajs/svelte";
  import Logo from "$lib/components/logo.svelte";
  import {
    UserCircle,
    Menu,
    LogOut,
    FolderOpen,
    BarChart3,
    X,
  } from "lucide-svelte";
  import * as DropdownMenu from "$lib/components/ui/dropdown-menu/index.js";
  import { Button, buttonVariants } from "$lib/components/ui/button/index.js";
  import { cn } from "$lib/utils.js";
  import {
    rootPath,
    loginPath,
    signupPath,
    logoutPath,
    projectsPath,
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
</script>

<nav class="sticky top-0 z-50 bg-white border-b shadow-sm">
  <div class="flex items-center justify-between p-4 lg:px-10">
    <div class="flex items-center gap-4 lg:gap-8">
      <Link href="/" onclick={closeMobileMenu}>
        <Logo class="h-8 w-32 lg:h-10 lg:w-42 text-primary" />
      </Link>

      <!-- Desktop Navigation -->
      <div class="hidden lg:flex items-center">
        {#if currentUser}
          <Link
            href="/dashboard"
            class={cn(
              buttonVariants({ variant: "ghost" }),
              "rounded-full text-muted-foreground hover:text-foreground",
            )}>Dashboard</Link
          >
          <Link
            href="/projects"
            class={cn(
              buttonVariants({ variant: "ghost" }),
              "rounded-full text-muted-foreground hover:text-foreground",
            )}>Projects</Link
          >
        {:else}
          {#each links as link}
            <Link
              href={link.href}
              class={cn(
                buttonVariants({ variant: "ghost" }),
                "rounded-full text-muted-foreground hover:text-foreground",
              )}>{link.label}</Link
            >
          {/each}
        {/if}
      </div>
    </div>

    <!-- Desktop User Menu -->
    <div class="hidden lg:block">
      {#if currentUser}
        <DropdownMenu.Root>
          <DropdownMenu.Trigger
            class={cn(
              buttonVariants({ variant: "outline" }),
              "rounded-full px-2.5 gap-1 h-10",
            )}
          >
            <Menu class="h-4 w-4" />
            <UserCircle class="h-4 w-4" />
          </DropdownMenu.Trigger>
          <DropdownMenu.Content class="w-56" align="end">
            <DropdownMenu.Group>
              <DropdownMenu.GroupHeading>
                <div class="text-xs font-normal text-muted-foreground">
                  Logged in as
                </div>
                <div class="text-sm font-semibold truncate">
                  {$page.props.user.email_address}
                </div>
              </DropdownMenu.GroupHeading>
              <DropdownMenu.Separator />
              <DropdownMenu.Item onclick={() => router.visit("/dashboard")}>
                <BarChart3 class="mr-2 size-4" />
                <span>Dashboard</span>
              </DropdownMenu.Item>
              <DropdownMenu.Item onclick={() => router.visit(projectsPath())}>
                <FolderOpen class="mr-2 size-4" />
                <span>Projects</span>
              </DropdownMenu.Item>
              <DropdownMenu.Item onclick={handleLogout}>
                <LogOut class="mr-2 size-4" />
                <span>Log out</span>
              </DropdownMenu.Item>
            </DropdownMenu.Group>
          </DropdownMenu.Content>
        </DropdownMenu.Root>
      {:else}
        <div class="flex items-center gap-2">
          <Link
            href={loginPath()}
            class={cn(buttonVariants({ variant: "ghost" }), "rounded-full")}
            >Log in</Link
          >
          <Link
            href={signupPath()}
            class={cn(buttonVariants({ variant: "default" }), "rounded-full")}
            >Sign up</Link
          >
        </div>
      {/if}
    </div>

    <!-- Mobile Menu Button -->
    <div class="lg:hidden">
      <button
        type="button"
        onclick={toggleMobileMenu}
        class={cn(
          buttonVariants({ variant: "outline" }),
          "rounded-full p-2 h-10 w-10",
        )}
        aria-label="Toggle mobile menu"
      >
        {#if mobileMenuOpen}
          <X class="h-5 w-5" />
        {:else}
          <Menu class="h-5 w-5" />
        {/if}
      </button>
    </div>
  </div>

  <!-- Mobile Menu -->
  {#if mobileMenuOpen}
    <div class="lg:hidden border-t bg-white">
      <div class="px-4 py-4 space-y-2">
        {#if currentUser}
          <!-- User Info -->
          <div class="px-3 py-2 border-b border-gray-100 mb-2">
            <div class="text-xs font-normal text-muted-foreground">
              Logged in as
            </div>
            <div class="text-sm font-semibold truncate">
              {$page.props.user.email_address}
            </div>
          </div>

          <!-- Navigation Links -->
          <Link
            href="/dashboard"
            onclick={closeMobileMenu}
            class="flex items-center gap-3 px-3 py-3 text-base font-medium text-gray-900 hover:bg-gray-50 rounded-lg transition-colors"
          >
            <BarChart3 class="h-5 w-5 text-gray-500" />
            Dashboard
          </Link>
          <Link
            href="/projects"
            onclick={closeMobileMenu}
            class="flex items-center gap-3 px-3 py-3 text-base font-medium text-gray-900 hover:bg-gray-50 rounded-lg transition-colors"
          >
            <FolderOpen class="h-5 w-5 text-gray-500" />
            Projects
          </Link>
          <button
            type="button"
            onclick={() => {
              handleLogout(event);
              closeMobileMenu();
            }}
            class="flex items-center gap-3 px-3 py-3 text-base font-medium text-red-600 hover:bg-red-50 rounded-lg transition-colors w-full text-left"
          >
            <LogOut class="h-5 w-5" />
            Log out
          </button>
        {:else}
          <!-- Guest Navigation -->
          {#each links as link}
            <Link
              href={link.href}
              onclick={closeMobileMenu}
              class="block px-3 py-3 text-base font-medium text-gray-900 hover:bg-gray-50 rounded-lg transition-colors"
            >
              {link.label}
            </Link>
          {/each}

          <!-- Auth Buttons -->
          <div class="pt-4 border-t border-gray-100 space-y-2">
            <Link
              href={loginPath()}
              onclick={closeMobileMenu}
              class={cn(
                buttonVariants({ variant: "outline" }),
                "w-full justify-center h-12 text-base",
              )}
            >
              Log in
            </Link>
            <Link
              href={signupPath()}
              onclick={closeMobileMenu}
              class={cn(
                buttonVariants({ variant: "default" }),
                "w-full justify-center h-12 text-base",
              )}
            >
              Sign up
            </Link>
          </div>
        {/if}
      </div>
    </div>
  {/if}
</nav>
