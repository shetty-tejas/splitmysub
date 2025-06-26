<script>
  import { page } from "@inertiajs/svelte";
  import AdminLayout from "../../../layouts/admin-layout.svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "../../../lib/components/ui/card";
  import { Badge } from "../../../lib/components/ui/badge";
  import ResponsiveTable from "../../../lib/components/ui/responsive-table.svelte";

  export let projects = [];
  export let total_projects = 0;
  export let total_users = 0;
  export let total_memberships = 0;

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString();
  }

  function getBadgeVariant(active) {
    return active ? "default" : "secondary";
  }

  function getDaysUntilRenewalText(days) {
    if (days < 0) return `${Math.abs(days)} days overdue`;
    if (days === 0) return "Due today";
    return `${days} days remaining`;
  }

  function getDaysUntilRenewalVariant(days) {
    if (days < 0) return "destructive";
    if (days <= 7) return "default";
    return "secondary";
  }

  const columns = [
    { key: "name", label: "Project Name", sortable: true },
    { key: "owner", label: "Owner", sortable: false },
    { key: "members", label: "Members", sortable: false },
    { key: "cost", label: "Cost", sortable: true },
    { key: "status", label: "Status", sortable: false },
    { key: "renewal", label: "Renewal", sortable: true },
    { key: "created", label: "Created", sortable: true },
  ];

  function formatMembersList(members) {
    if (members.length === 0) return "No members";
    if (members.length <= 2) {
      return members.map((m) => m.email).join(", ");
    }
    return `${members
      .slice(0, 2)
      .map((m) => m.email)
      .join(", ")} +${members.length - 2} more`;
  }
</script>

<AdminLayout title="Projects Management">
  <div class="space-y-6">
    <!-- Header -->
    <div>
      <h1 class="text-3xl font-bold text-gray-900">Projects Management</h1>
      <p class="text-gray-600 mt-2">
        View and manage all projects across the platform
      </p>
    </div>

    <!-- Summary Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <Card>
        <CardHeader class="pb-3">
          <CardTitle class="text-sm font-medium text-gray-600">
            Total Projects
          </CardTitle>
          <div class="text-2xl font-bold text-blue-600">{total_projects}</div>
        </CardHeader>
      </Card>

      <Card>
        <CardHeader class="pb-3">
          <CardTitle class="text-sm font-medium text-gray-600">
            Total Users
          </CardTitle>
          <div class="text-2xl font-bold text-green-600">{total_users}</div>
        </CardHeader>
      </Card>

      <Card>
        <CardHeader class="pb-3">
          <CardTitle class="text-sm font-medium text-gray-600">
            Total Memberships
          </CardTitle>
          <div class="text-2xl font-bold text-purple-600">
            {total_memberships}
          </div>
        </CardHeader>
      </Card>
    </div>

    <!-- Projects Table -->
    <Card>
      <CardHeader>
        <CardTitle>All Projects</CardTitle>
        <CardDescription>
          Complete list of all projects with owner and member information
        </CardDescription>
      </CardHeader>
      <CardContent>
        {#if projects.length === 0}
          <div class="text-center py-8 text-gray-500">
            <p>No projects found.</p>
          </div>
        {:else}
          <ResponsiveTable {columns} data={projects}>
            {#snippet children(item, column, index)}
              {#if column.key === "name"}
                <div class="space-y-1">
                  <div class="font-medium text-gray-900">{item.name}</div>
                  <div class="text-sm text-gray-500">ID: {item.slug}</div>
                  {#if item.description}
                    <div class="text-xs text-gray-400 truncate max-w-xs">
                      {item.description}
                    </div>
                  {/if}
                </div>
              {:else if column.key === "owner"}
                <div class="space-y-1">
                  <div class="font-medium text-gray-900">{item.owner.name}</div>
                  <div class="text-sm text-blue-600">{item.owner.email}</div>
                </div>
              {:else if column.key === "members"}
                <div class="space-y-1">
                  <div class="text-sm font-medium">
                    {item.members.length} member{item.members.length !== 1
                      ? "s"
                      : ""}
                  </div>
                  {#if item.members.length > 0}
                    <div class="text-xs text-gray-500">
                      {formatMembersList(item.members)}
                    </div>
                  {/if}
                  <div class="text-xs text-gray-400">
                    Total: {item.total_members} ({item.formatted_cost_per_member}/person)
                  </div>
                </div>
              {:else if column.key === "cost"}
                <div class="space-y-1">
                  <div class="font-medium text-gray-900">
                    {item.formatted_cost}
                  </div>
                  <div class="text-xs text-gray-500 capitalize">
                    {item.billing_cycle}
                  </div>
                </div>
              {:else if column.key === "status"}
                <div class="space-y-2">
                  <Badge variant={getBadgeVariant(item.active)}>
                    {item.active ? "Active" : "Expired"}
                  </Badge>
                  {#if item.subscription_url}
                    <div class="text-xs">
                      <a
                        href={item.subscription_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        class="text-blue-600 hover:text-blue-800"
                      >
                        View Subscription ↗
                      </a>
                    </div>
                  {/if}
                </div>
              {:else if column.key === "renewal"}
                <div class="space-y-1">
                  <div class="text-sm font-medium">
                    {formatDate(item.renewal_date)}
                  </div>
                  <Badge
                    variant={getDaysUntilRenewalVariant(
                      item.days_until_renewal,
                    )}
                    class="text-xs"
                  >
                    {getDaysUntilRenewalText(item.days_until_renewal)}
                  </Badge>
                </div>
              {:else if column.key === "created"}
                <div class="text-sm text-gray-600">
                  {formatDate(item.created_at)}
                </div>
              {/if}
            {/snippet}
          </ResponsiveTable>
        {/if}
      </CardContent>
    </Card>
  </div>
</AdminLayout>
