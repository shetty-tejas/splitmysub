<script>
  import Layout from "../../layouts/layout.svelte";
  import * as Card from "$lib/components/ui/card/index.js";
  import { Button } from "$lib/components/ui/button/index.js";
  import { Badge } from "$lib/components/ui/badge/index.js";
  import { Link } from "@inertiajs/svelte";
  import {
    DollarSign,
    CreditCard,
    AlertTriangle,
    CheckCircle,
    Clock,
    Calendar,
    Users,
    ArrowRight,
    Plus,
    Eye,
    Download,
    BarChart3,
  } from "lucide-svelte";

  export let user_projects = [];
  export let member_projects = [];
  export let recent_payments = [];
  export let upcoming_cycles = [];
  export let stats = {};

  function formatCurrency(amount) {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: "USD",
    }).format(amount);
  }

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  }

  function getStatusColor(status) {
    switch (status) {
      case "confirmed":
        return "bg-green-100 text-green-800";
      case "pending":
        return "bg-yellow-100 text-yellow-800";
      case "rejected":
        return "bg-red-100 text-red-800";
      case "overdue":
        return "bg-red-100 text-red-800";
      default:
        return "bg-gray-100 text-gray-800";
    }
  }

  function getDaysUntilDueColor(days) {
    if (days < 0) return "text-red-600";
    if (days <= 3) return "text-orange-600";
    if (days <= 7) return "text-yellow-600";
    return "text-green-600";
  }
</script>

<svelte:head>
  <title>Dashboard - SplitSub</title>
</svelte:head>

<Layout>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold text-gray-900">Dashboard</h1>
      <p class="mt-2 text-gray-600">
        Overview of your subscriptions and payments
      </p>
    </div>

    <!-- Stats Cards -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <Users class="h-8 w-8 text-blue-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Total Projects</p>
              <p class="text-2xl font-bold text-gray-900">
                {stats.total_projects || 0}
              </p>
              <p class="text-xs text-gray-500">
                {stats.owned_projects || 0} owned, {stats.member_projects || 0} member
              </p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <DollarSign class="h-8 w-8 text-green-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Monthly Cost</p>
              <p class="text-2xl font-bold text-gray-900">
                {formatCurrency(stats.total_monthly_cost || 0)}
              </p>
              <p class="text-xs text-gray-500">Total monthly subscriptions</p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <CheckCircle class="h-8 w-8 text-green-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Payments Made</p>
              <p class="text-2xl font-bold text-gray-900">
                {stats.total_payments_made || 0}
              </p>
              <p class="text-xs text-gray-500">
                {formatCurrency(stats.total_amount_paid || 0)} total
              </p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <AlertTriangle class="h-8 w-8 text-orange-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Pending/Overdue</p>
              <p class="text-2xl font-bold text-gray-900">
                {(stats.pending_payments || 0) + (stats.overdue_payments || 0)}
              </p>
              <p class="text-xs text-gray-500">
                {stats.pending_payments || 0} pending, {stats.overdue_payments ||
                  0} overdue
              </p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
      <!-- Recent Payments -->
      <Card.Root>
        <Card.Header>
          <div class="flex items-center justify-between">
            <Card.Title class="flex items-center gap-2">
              <CreditCard class="h-5 w-5" />
              Recent Payments
            </Card.Title>
            <Link href="/dashboard/payment_history">
              <Button variant="outline" size="sm">
                View All
                <ArrowRight class="h-4 w-4 ml-1" />
              </Button>
            </Link>
          </div>
        </Card.Header>
        <Card.Content>
          {#if recent_payments.length > 0}
            <div class="space-y-4">
              {#each recent_payments as payment}
                <div
                  class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                >
                  <div class="flex items-center space-x-3">
                    <div class="flex-shrink-0">
                      {#if payment.status === "confirmed"}
                        <CheckCircle class="h-5 w-5 text-green-600" />
                      {:else if payment.status === "pending"}
                        <Clock class="h-5 w-5 text-yellow-600" />
                      {:else}
                        <AlertTriangle class="h-5 w-5 text-red-600" />
                      {/if}
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900">
                        {payment.project.name}
                      </p>
                      <p class="text-xs text-gray-500">
                        {formatDate(payment.created_at)} • Due: {formatDate(
                          payment.billing_cycle.due_date,
                        )}
                      </p>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-sm font-medium text-gray-900">
                      {formatCurrency(payment.amount)}
                    </p>
                    <Badge class={getStatusColor(payment.status)}>
                      {payment.status}
                    </Badge>
                  </div>
                </div>
              {/each}
            </div>
          {:else}
            <div class="text-center py-8">
              <CreditCard class="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p class="text-gray-500">No recent payments</p>
            </div>
          {/if}
        </Card.Content>
      </Card.Root>

      <!-- Upcoming Payments -->
      <Card.Root>
        <Card.Header>
          <div class="flex items-center justify-between">
            <Card.Title class="flex items-center gap-2">
              <Calendar class="h-5 w-5" />
              Upcoming Payments
            </Card.Title>
            <Link href="/dashboard/upcoming_payments">
              <Button variant="outline" size="sm">
                View Calendar
                <ArrowRight class="h-4 w-4 ml-1" />
              </Button>
            </Link>
          </div>
        </Card.Header>
        <Card.Content>
          {#if upcoming_cycles.length > 0}
            <div class="space-y-4">
              {#each upcoming_cycles as cycle}
                <div
                  class="flex items-center justify-between p-3 bg-gray-50 rounded-lg"
                >
                  <div class="flex items-center space-x-3">
                    <div class="flex-shrink-0">
                      <Calendar class="h-5 w-5 text-blue-600" />
                    </div>
                    <div>
                      <p class="text-sm font-medium text-gray-900">
                        {cycle.project.name}
                      </p>
                      <p class="text-xs text-gray-500">
                        Due: {formatDate(cycle.due_date)}
                      </p>
                    </div>
                  </div>
                  <div class="text-right">
                    <p class="text-sm font-medium text-gray-900">
                      {formatCurrency(cycle.expected_payment)}
                    </p>
                    <p
                      class="text-xs {getDaysUntilDueColor(
                        cycle.days_until_due,
                      )}"
                    >
                      {#if cycle.days_until_due < 0}
                        {Math.abs(cycle.days_until_due)} days overdue
                      {:else if cycle.days_until_due === 0}
                        Due today
                      {:else}
                        {cycle.days_until_due} days left
                      {/if}
                    </p>
                  </div>
                </div>
              {/each}
            </div>
          {:else}
            <div class="text-center py-8">
              <Calendar class="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p class="text-gray-500">No upcoming payments</p>
            </div>
          {/if}
        </Card.Content>
      </Card.Root>
    </div>

    <!-- Projects Overview -->
    <div class="mt-8">
      <Card.Root>
        <Card.Header>
          <div class="flex items-center justify-between">
            <Card.Title class="flex items-center gap-2">
              <Users class="h-5 w-5" />
              Your Projects
            </Card.Title>
            <div class="flex gap-2">
              <Link href="/dashboard/analytics">
                <Button variant="outline" size="sm">
                  <BarChart3 class="h-4 w-4 mr-1" />
                  Analytics
                </Button>
              </Link>
              <Link href="/projects/new">
                <Button size="sm">
                  <Plus class="h-4 w-4 mr-1" />
                  New Project
                </Button>
              </Link>
            </div>
          </div>
        </Card.Header>
        <Card.Content>
          {#if user_projects.length > 0 || member_projects.length > 0}
            <div class="space-y-6">
              {#if user_projects.length > 0}
                <div>
                  <h3 class="text-lg font-medium text-gray-900 mb-4">
                    Owned Projects
                  </h3>
                  <div
                    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
                  >
                    {#each user_projects as project}
                      <div
                        class="border rounded-lg p-4 hover:shadow-md transition-shadow"
                      >
                        <div class="flex items-center justify-between mb-2">
                          <h4 class="font-medium text-gray-900">
                            {project.name}
                          </h4>
                          <Badge class={getStatusColor(project.payment_status)}>
                            {project.payment_status}
                          </Badge>
                        </div>
                        <p class="text-sm text-gray-600 mb-2">
                          {formatCurrency(project.cost)} / {project.billing_cycle}
                        </p>
                        <p class="text-xs text-gray-500 mb-3">
                          {project.total_members} members
                        </p>
                        <div class="flex gap-2">
                          <Link href="/projects/{project.id}">
                            <Button variant="outline" size="sm">
                              <Eye class="h-3 w-3 mr-1" />
                              View
                            </Button>
                          </Link>
                        </div>
                      </div>
                    {/each}
                  </div>
                </div>
              {/if}

              {#if member_projects.length > 0}
                <div>
                  <h3 class="text-lg font-medium text-gray-900 mb-4">
                    Member Projects
                  </h3>
                  <div
                    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4"
                  >
                    {#each member_projects as project}
                      <div
                        class="border rounded-lg p-4 hover:shadow-md transition-shadow"
                      >
                        <div class="flex items-center justify-between mb-2">
                          <h4 class="font-medium text-gray-900">
                            {project.name}
                          </h4>
                          <Badge class={getStatusColor(project.payment_status)}>
                            {project.payment_status}
                          </Badge>
                        </div>
                        <p class="text-sm text-gray-600 mb-2">
                          {formatCurrency(project.cost_per_member)} / {project.billing_cycle}
                        </p>
                        <p class="text-xs text-gray-500 mb-3">
                          {project.total_members} members
                        </p>
                        <div class="flex gap-2">
                          <Link href="/projects/{project.id}">
                            <Button variant="outline" size="sm">
                              <Eye class="h-3 w-3 mr-1" />
                              View
                            </Button>
                          </Link>
                        </div>
                      </div>
                    {/each}
                  </div>
                </div>
              {/if}
            </div>
          {:else}
            <div class="text-center py-12">
              <Users class="h-16 w-16 text-gray-400 mx-auto mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">
                No projects yet
              </h3>
              <p class="text-gray-500 mb-6">
                Create your first project to start splitting subscription costs
              </p>
              <Link href="/projects/new">
                <Button>
                  <Plus class="h-4 w-4 mr-2" />
                  Create Project
                </Button>
              </Link>
            </div>
          {/if}
        </Card.Content>
      </Card.Root>
    </div>

    <!-- Quick Actions -->
    <div class="mt-8">
      <Card.Root>
        <Card.Header>
          <Card.Title>Quick Actions</Card.Title>
        </Card.Header>
        <Card.Content>
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <Link href="/dashboard/payment_history">
              <Button variant="outline" class="w-full justify-start">
                <CreditCard class="h-4 w-4 mr-2" />
                Payment History
              </Button>
            </Link>
            <Link href="/dashboard/upcoming_payments">
              <Button variant="outline" class="w-full justify-start">
                <Calendar class="h-4 w-4 mr-2" />
                Upcoming Payments
              </Button>
            </Link>
            <Link href="/dashboard/analytics">
              <Button variant="outline" class="w-full justify-start">
                <BarChart3 class="h-4 w-4 mr-2" />
                Analytics
              </Button>
            </Link>
            <Link href="/dashboard/export_payments">
              <Button variant="outline" class="w-full justify-start">
                <Download class="h-4 w-4 mr-2" />
                Export Data
              </Button>
            </Link>
          </div>
        </Card.Content>
      </Card.Root>
    </div>
  </div>
</Layout>
