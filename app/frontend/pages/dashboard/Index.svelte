<script>
  import { page } from "@inertiajs/svelte";
  import { router } from "@inertiajs/svelte";
  import Layout from "../../layouts/layout.svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Button } from "$lib/components/ui/button";
  import { Badge } from "$lib/components/ui/badge";
  import {
    Plus,
    Calendar,
    DollarSign,
    Users,
    AlertTriangle,
  } from "lucide-svelte";
  import {
    formatCurrency,
    formatDate,
    getBillingCycleBadgeVariant,
    getProjectStatusBadgeVariant,
    getProjectStatusText,
  } from "$lib/billing-utils";

  export let owned_projects = [];
  export let member_projects = [];
</script>

<svelte:head>
  <title>Dashboard - SplitMySub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <div class="flex justify-between items-center mb-8">
      <div>
        <h1 class="text-3xl font-bold tracking-tight">Dashboard</h1>
        <p class="text-muted-foreground">
          Manage your subscription projects and memberships
        </p>
      </div>
      <Button href="/projects/new" class="flex items-center gap-2">
        <Plus class="h-4 w-4" />
        New Project
      </Button>
    </div>

    <!-- Owned Projects -->
    {#if owned_projects.length > 0}
      <div class="mb-8">
        <h2 class="text-2xl font-semibold mb-4">Your Projects</h2>
        <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {#each owned_projects as project}
            <div
              class="bg-card text-card-foreground rounded-xl border shadow cursor-pointer hover:shadow-md transition-shadow"
              onclick={() => {
                router.get(`/projects/${project.slug}`);
              }}
              role="button"
              tabindex="0"
              onkeydown={(e) =>
                e.key === "Enter" && router.get(`/projects/${project.slug}`)}
            >
              <CardHeader class="pb-3">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <CardTitle class="text-lg">{project.name}</CardTitle>
                    {#if project.description}
                      <CardDescription class="mt-1"
                        >{project.description}</CardDescription
                      >
                    {/if}
                  </div>
                  <Badge
                    variant={getProjectStatusBadgeVariant(project)}
                    class="ml-2"
                  >
                    {getProjectStatusText(project)}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent class="space-y-3">
                <div class="flex items-center justify-between">
                  <div
                    class="flex items-center gap-2 text-sm text-muted-foreground"
                  >
                    <DollarSign class="h-4 w-4" />
                    <span>{formatCurrency(project.cost)}</span>
                  </div>
                  <Badge
                    variant={getBillingCycleBadgeVariant(project.billing_cycle)}
                  >
                    {project.billing_cycle}
                  </Badge>
                </div>

                <div
                  class="flex items-center gap-2 text-sm text-muted-foreground"
                >
                  <Calendar class="h-4 w-4" />
                  <span>Renews {formatDate(project.renewal_date)}</span>
                </div>

                <div class="flex items-center justify-between">
                  <div
                    class="flex items-center gap-2 text-sm text-muted-foreground"
                  >
                    <Users class="h-4 w-4" />
                    <span
                      >{project.total_members} member{project.total_members !==
                      1
                        ? "s"
                        : ""}</span
                    >
                  </div>
                  <div class="text-sm font-medium">
                    {formatCurrency(project.cost_per_member)}/person
                  </div>
                </div>

                {#if project.expiring_soon}
                  <div
                    class="flex items-center gap-2 text-sm text-amber-600 bg-amber-50 p-2 rounded"
                  >
                    <AlertTriangle class="h-4 w-4" />
                    <span>Renewal reminder in {project.reminder_days} days</span
                    >
                  </div>
                {/if}
              </CardContent>
            </div>
          {/each}
        </div>
      </div>
    {:else if member_projects.length === 0}
      <!-- Only show "No projects yet" if user has no owned projects AND no member projects -->
      <div class="mb-8">
        <h2 class="text-2xl font-semibold mb-4">Your Projects</h2>
        <Card class="text-center py-8">
          <CardContent>
            <div class="flex flex-col items-center gap-4">
              <div class="rounded-full bg-muted p-4">
                <Plus class="h-8 w-8 text-muted-foreground" />
              </div>
              <div>
                <h3 class="text-lg font-semibold">No projects yet</h3>
                <p class="text-muted-foreground">
                  Create your first subscription project to get started
                </p>
              </div>
              <Button href="/projects/new" class="flex items-center gap-2">
                <Plus class="h-4 w-4" />
                Create Project
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>
    {/if}

    <!-- Member Projects -->
    {#if member_projects.length > 0}
      <div>
        <h2 class="text-2xl font-semibold mb-4">Projects You're In</h2>
        <div class="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {#each member_projects as project}
            <div
              class="bg-card text-card-foreground rounded-xl border shadow cursor-pointer hover:shadow-md transition-shadow"
              onclick={() => {
                router.get(`/projects/${project.slug}`);
              }}
              role="button"
              tabindex="0"
              onkeydown={(e) =>
                e.key === "Enter" && router.get(`/projects/${project.slug}`)}
            >
              <CardHeader class="pb-3">
                <div class="flex justify-between items-start">
                  <div class="flex-1">
                    <CardTitle class="text-lg">{project.name}</CardTitle>
                    {#if project.description}
                      <CardDescription class="mt-1"
                        >{project.description}</CardDescription
                      >
                    {/if}
                  </div>
                  <Badge
                    variant={getProjectStatusBadgeVariant(project)}
                    class="ml-2"
                  >
                    {getProjectStatusText(project)}
                  </Badge>
                </div>
              </CardHeader>
              <CardContent class="space-y-3">
                <div class="flex items-center justify-between">
                  <div
                    class="flex items-center gap-2 text-sm text-muted-foreground"
                  >
                    <DollarSign class="h-4 w-4" />
                    <span>{formatCurrency(project.cost_per_member)}/person</span
                    >
                  </div>
                  <Badge
                    variant={getBillingCycleBadgeVariant(project.billing_cycle)}
                  >
                    {project.billing_cycle}
                  </Badge>
                </div>

                <div
                  class="flex items-center gap-2 text-sm text-muted-foreground"
                >
                  <Calendar class="h-4 w-4" />
                  <span>Renews {formatDate(project.renewal_date)}</span>
                </div>

                <div
                  class="flex items-center gap-2 text-sm text-muted-foreground"
                >
                  <Users class="h-4 w-4" />
                  <span
                    >{project.total_members} member{project.total_members !== 1
                      ? "s"
                      : ""}</span
                  >
                </div>

                {#if project.expiring_soon}
                  <div
                    class="flex items-center gap-2 text-sm text-amber-600 bg-amber-50 p-2 rounded"
                  >
                    <AlertTriangle class="h-4 w-4" />
                    <span>Renewal reminder in {project.reminder_days} days</span
                    >
                  </div>
                {/if}
              </CardContent>
            </div>
          {/each}
        </div>
      </div>
    {/if}
  </div>
</Layout>
