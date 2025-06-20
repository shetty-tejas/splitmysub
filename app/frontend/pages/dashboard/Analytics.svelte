<script>
  import Layout from "../../layouts/layout.svelte";
  import * as Card from "$lib/components/ui/card/index.js";
  import { Button } from "$lib/components/ui/button/index.js";
  import { Badge } from "$lib/components/ui/badge/index.js";
  import { Link } from "@inertiajs/svelte";
  import {
    ArrowLeft,
    BarChart3,
    TrendingUp,
    TrendingDown,
    DollarSign,
    PieChart,
    Calendar,
    Percent,
  } from "lucide-svelte";
  import { formatCurrency } from "$lib/billing-utils";

  export let analytics = {};

  function getMaxAmount(data) {
    return Math.max(...data.map((item) => item.amount));
  }

  function getBarHeight(amount, maxAmount) {
    return maxAmount > 0 ? (amount / maxAmount) * 100 : 0;
  }

  function getTotalProjectCost() {
    return (
      analytics.project_cost_breakdown?.reduce(
        (sum, project) => sum + project.cost,
        0,
      ) || 0
    );
  }

  function getProjectPercentage(cost) {
    const total = getTotalProjectCost();
    return total > 0 ? ((cost / total) * 100).toFixed(1) : 0;
  }

  function getTotalPayments() {
    const breakdown = analytics.payment_status_breakdown || {};
    return (
      (breakdown.confirmed || 0) +
      (breakdown.pending || 0) +
      (breakdown.rejected || 0)
    );
  }

  function getStatusPercentage(count) {
    const total = getTotalPayments();
    return total > 0 ? ((count / total) * 100).toFixed(1) : 0;
  }

  $: monthlySpending = analytics.monthly_spending || [];
  $: paymentBreakdown = analytics.payment_status_breakdown || {};
  $: projectBreakdown = analytics.project_cost_breakdown || [];
  $: savingsAnalysis = analytics.savings_analysis || {};
  $: maxMonthlyAmount = getMaxAmount(monthlySpending);
</script>

<svelte:head>
  <title>Analytics - SplitSub</title>
</svelte:head>

<Layout>
  <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Header -->
    <div class="mb-8">
      <div class="flex items-center gap-4 mb-4">
        <Link href="/dashboard">
          <Button variant="outline" size="sm">
            <ArrowLeft class="h-4 w-4 mr-2" />
            Back to Dashboard
          </Button>
        </Link>
      </div>
      <h1 class="text-3xl font-bold text-gray-900">Analytics</h1>
      <p class="mt-2 text-gray-600">
        Insights into your subscription spending and savings
      </p>
    </div>

    <!-- Key Metrics -->
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <DollarSign class="h-8 w-8 text-green-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Monthly Savings</p>
              <p class="text-2xl font-bold text-gray-900">
                {formatCurrency(savingsAnalysis.monthly_savings || 0)}
              </p>
              <p class="text-xs text-green-600">
                From {savingsAnalysis.projects_count || 0} shared projects
              </p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <TrendingUp class="h-8 w-8 text-blue-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Yearly Savings</p>
              <p class="text-2xl font-bold text-gray-900">
                {formatCurrency(savingsAnalysis.yearly_savings || 0)}
              </p>
              <p class="text-xs text-blue-600">Projected annual savings</p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <BarChart3 class="h-8 w-8 text-purple-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Total Projects</p>
              <p class="text-2xl font-bold text-gray-900">
                {projectBreakdown.length}
              </p>
              <p class="text-xs text-purple-600">Active subscriptions</p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>

      <Card.Root>
        <Card.Content class="p-6">
          <div class="flex items-center">
            <div class="flex-shrink-0">
              <PieChart class="h-8 w-8 text-orange-600" />
            </div>
            <div class="ml-4">
              <p class="text-sm font-medium text-gray-500">Total Payments</p>
              <p class="text-2xl font-bold text-gray-900">
                {getTotalPayments()}
              </p>
              <p class="text-xs text-orange-600">All time payments</p>
            </div>
          </div>
        </Card.Content>
      </Card.Root>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
      <!-- Monthly Spending Chart -->
      <Card.Root>
        <Card.Header>
          <Card.Title class="flex items-center gap-2">
            <BarChart3 class="h-5 w-5" />
            Monthly Spending Trend
          </Card.Title>
        </Card.Header>
        <Card.Content>
          {#if monthlySpending.length > 0}
            <div class="space-y-4">
              {#each monthlySpending as month}
                <div class="flex items-center justify-between">
                  <span class="text-sm font-medium text-gray-700 w-20"
                    >{month.month}</span
                  >
                  <div class="flex-1 mx-4">
                    <div class="bg-gray-200 rounded-full h-4 relative">
                      <div
                        class="bg-blue-600 h-4 rounded-full transition-all duration-300"
                        style="width: {getBarHeight(
                          month.amount,
                          maxMonthlyAmount,
                        )}%"
                      ></div>
                    </div>
                  </div>
                  <span class="text-sm font-bold text-gray-900 w-20 text-right">
                    {formatCurrency(month.amount)}
                  </span>
                </div>
              {/each}
            </div>
          {:else}
            <div class="text-center py-8">
              <BarChart3 class="h-12 w-12 text-gray-400 mx-auto mb-4" />
              <p class="text-gray-500">No spending data available</p>
            </div>
          {/if}
        </Card.Content>
      </Card.Root>

      <!-- Payment Status Breakdown -->
      <Card.Root>
        <Card.Header>
          <Card.Title class="flex items-center gap-2">
            <PieChart class="h-5 w-5" />
            Payment Status Breakdown
          </Card.Title>
        </Card.Header>
        <Card.Content>
          <div class="space-y-4">
            <div
              class="flex items-center justify-between p-3 bg-green-50 rounded-lg"
            >
              <div class="flex items-center gap-3">
                <div class="w-4 h-4 bg-green-600 rounded-full"></div>
                <span class="font-medium text-gray-900">Confirmed</span>
              </div>
              <div class="text-right">
                <span class="text-lg font-bold text-gray-900"
                  >{paymentBreakdown.confirmed || 0}</span
                >
                <span class="text-sm text-gray-500 ml-2"
                  >({getStatusPercentage(
                    paymentBreakdown.confirmed || 0,
                  )}%)</span
                >
              </div>
            </div>

            <div
              class="flex items-center justify-between p-3 bg-yellow-50 rounded-lg"
            >
              <div class="flex items-center gap-3">
                <div class="w-4 h-4 bg-yellow-600 rounded-full"></div>
                <span class="font-medium text-gray-900">Pending</span>
              </div>
              <div class="text-right">
                <span class="text-lg font-bold text-gray-900"
                  >{paymentBreakdown.pending || 0}</span
                >
                <span class="text-sm text-gray-500 ml-2"
                  >({getStatusPercentage(paymentBreakdown.pending || 0)}%)</span
                >
              </div>
            </div>

            <div
              class="flex items-center justify-between p-3 bg-red-50 rounded-lg"
            >
              <div class="flex items-center gap-3">
                <div class="w-4 h-4 bg-red-600 rounded-full"></div>
                <span class="font-medium text-gray-900">Rejected</span>
              </div>
              <div class="text-right">
                <span class="text-lg font-bold text-gray-900"
                  >{paymentBreakdown.rejected || 0}</span
                >
                <span class="text-sm text-gray-500 ml-2"
                  >({getStatusPercentage(
                    paymentBreakdown.rejected || 0,
                  )}%)</span
                >
              </div>
            </div>

            {#if getTotalPayments() === 0}
              <div class="text-center py-8">
                <PieChart class="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <p class="text-gray-500">No payment data available</p>
              </div>
            {/if}
          </div>
        </Card.Content>
      </Card.Root>
    </div>

    <!-- Project Cost Breakdown -->
    <Card.Root class="mb-8">
      <Card.Header>
        <Card.Title class="flex items-center gap-2">
          <DollarSign class="h-5 w-5" />
          Project Cost Breakdown
        </Card.Title>
      </Card.Header>
      <Card.Content>
        {#if projectBreakdown.length > 0}
          <div class="space-y-4">
            {#each projectBreakdown as project}
              <div class="border rounded-lg p-4">
                <div class="flex items-center justify-between mb-2">
                  <div class="flex items-center gap-3">
                    <h3 class="font-medium text-gray-900">{project.name}</h3>
                    <Badge
                      variant={project.role === "owner"
                        ? "default"
                        : "secondary"}
                    >
                      {project.role}
                    </Badge>
                  </div>
                  <div class="text-right">
                    <span class="text-lg font-bold text-gray-900"
                      >{formatCurrency(project.cost)}</span
                    >
                    <span class="text-sm text-gray-500 ml-2"
                      >/ {project.billing_cycle}</span
                    >
                  </div>
                </div>
                <div class="flex items-center justify-between">
                  <div class="flex-1">
                    <div class="bg-gray-200 rounded-full h-2">
                      <div
                        class="bg-blue-600 h-2 rounded-full"
                        style="width: {getProjectPercentage(project.cost)}%"
                      ></div>
                    </div>
                  </div>
                  <span class="text-xs text-gray-500 ml-3">
                    {getProjectPercentage(project.cost)}% of total
                  </span>
                </div>
              </div>
            {/each}

            <div class="border-t pt-4 mt-4">
              <div class="flex items-center justify-between">
                <span class="text-lg font-medium text-gray-900"
                  >Total Monthly Cost</span
                >
                <span class="text-xl font-bold text-gray-900"
                  >{formatCurrency(getTotalProjectCost())}</span
                >
              </div>
            </div>
          </div>
        {:else}
          <div class="text-center py-8">
            <DollarSign class="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p class="text-gray-500">No project data available</p>
          </div>
        {/if}
      </Card.Content>
    </Card.Root>

    <!-- Savings Analysis -->
    <Card.Root>
      <Card.Header>
        <Card.Title class="flex items-center gap-2">
          <TrendingUp class="h-5 w-5" />
          Savings Analysis
        </Card.Title>
      </Card.Header>
      <Card.Content>
        {#if savingsAnalysis.projects_count > 0}
          <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div class="text-center p-6 bg-green-50 rounded-lg">
              <TrendingUp class="h-12 w-12 text-green-600 mx-auto mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">
                Monthly Savings
              </h3>
              <p class="text-3xl font-bold text-green-600">
                {formatCurrency(savingsAnalysis.monthly_savings)}
              </p>
              <p class="text-sm text-gray-600 mt-2">
                Saved this month by sharing subscriptions
              </p>
            </div>

            <div class="text-center p-6 bg-blue-50 rounded-lg">
              <Calendar class="h-12 w-12 text-blue-600 mx-auto mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">
                Yearly Projection
              </h3>
              <p class="text-3xl font-bold text-blue-600">
                {formatCurrency(savingsAnalysis.yearly_savings)}
              </p>
              <p class="text-sm text-gray-600 mt-2">Projected annual savings</p>
            </div>

            <div class="text-center p-6 bg-purple-50 rounded-lg">
              <Percent class="h-12 w-12 text-purple-600 mx-auto mb-4" />
              <h3 class="text-lg font-medium text-gray-900 mb-2">
                Shared Projects
              </h3>
              <p class="text-3xl font-bold text-purple-600">
                {savingsAnalysis.projects_count}
              </p>
              <p class="text-sm text-gray-600 mt-2">
                Projects where you're saving money
              </p>
            </div>
          </div>

          <div
            class="mt-8 p-6 bg-gradient-to-r from-green-50 to-blue-50 rounded-lg"
          >
            <div class="flex items-center gap-4">
              <TrendingUp class="h-8 w-8 text-green-600" />
              <div>
                <h3 class="text-lg font-medium text-gray-900">
                  Great job saving money!
                </h3>
                <p class="text-gray-600">
                  By sharing {savingsAnalysis.projects_count} subscription{savingsAnalysis.projects_count !==
                  1
                    ? "s"
                    : ""}, you're saving {formatCurrency(
                    savingsAnalysis.monthly_savings,
                  )} every month. That's {formatCurrency(
                    savingsAnalysis.yearly_savings,
                  )} per year!
                </p>
              </div>
            </div>
          </div>
        {:else}
          <div class="text-center py-12">
            <TrendingDown class="h-16 w-16 text-gray-400 mx-auto mb-4" />
            <h3 class="text-lg font-medium text-gray-900 mb-2">
              No savings yet
            </h3>
            <p class="text-gray-500 mb-6">
              Join shared subscription projects to start saving money on your
              monthly bills.
            </p>
            <Link href="/dashboard">
              <Button>Browse Projects</Button>
            </Link>
          </div>
        {/if}
      </Card.Content>
    </Card.Root>
  </div>
</Layout>
