<script>
  // grab page props from inertia
  import { page, Link, router } from "@inertiajs/svelte";
  import Logo from "$lib/components/logo.svelte";
  import { UserCircle, Menu, LogOut, FolderOpen } from "lucide-svelte";
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
</script>

<nav>
  <div class="flex items-center justify-between p-4 px-10 border-b">
    <div class="flex items-center gap-8">
      <Link href="/">
        <Logo class="h-10 w-42 text-primary" />
      </Link>
      <div class="hidden md:flex items-center">
        {#each links as link}
          <Link
            href={link.href}
            class={cn(
              buttonVariants({ variant: "ghost" }),
              "rounded-full text-muted-foreground",
            )}>{link.label}</Link
          >
        {/each}
      </div>
    </div>
    {#if currentUser}
      <DropdownMenu.Root>
        <DropdownMenu.Trigger
          class={cn(
            buttonVariants({ variant: "outline" }),
            "rounded-full px-2.5 gap-1",
          )}
        >
          <Menu />
          <UserCircle />
        </DropdownMenu.Trigger>
        <DropdownMenu.Content class="w-56" align="end">
          <DropdownMenu.Group>
            <DropdownMenu.GroupHeading>
              <div class="text-xs font-normal text-muted-foreground">
                Logged in as
              </div>
              <div class="text-sm font-semibold">
                {$page.props.user.email_address}
              </div>
            </DropdownMenu.GroupHeading>
            <DropdownMenu.Separator />
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
      <!-- Mobile -->
      <DropdownMenu.Root>
        <DropdownMenu.Trigger
          class={cn(
            buttonVariants({ variant: "outline" }),
            "rounded-full px-2.5 gap-1",
          )}
        >
          <Menu />
          <UserCircle />
        </DropdownMenu.Trigger>
        <DropdownMenu.Content class="w-56" align="end">
          <DropdownMenu.Group>
            <DropdownMenu.Item
              class="font-medium"
              onclick={() => router.visit(signupPath())}
              >Sign up</DropdownMenu.Item
            >
            <DropdownMenu.Item onclick={() => router.visit(loginPath())}
              >Log in</DropdownMenu.Item
            >
          </DropdownMenu.Group>
          <div class="md:hidden">
            <DropdownMenu.Separator />
            <DropdownMenu.Group>
              {#each links as link}
                <DropdownMenu.Item onclick={() => router.visit(link.href)}
                  >{link.label}</DropdownMenu.Item
                >
              {/each}
            </DropdownMenu.Group>
          </div>
        </DropdownMenu.Content>
      </DropdownMenu.Root>
    {/if}
  </div>
</nav>
