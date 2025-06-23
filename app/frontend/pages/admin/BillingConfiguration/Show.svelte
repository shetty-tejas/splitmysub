<script>
  import AdminLayout from "../../../layouts/admin-layout.svelte";
  import { Button } from "../../../lib/components/ui/button";
  import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
  } from "../../../lib/components/ui/card";
  import { Badge } from "../../../lib/components/ui/badge";
  import { Separator } from "../../../lib/components/ui/separator";
  import { router } from "@inertiajs/svelte";

  export let config;
  export let supported_frequencies;
  export let frequency_descriptions;
  export let validation_errors = [];
  export let preview_data;

  const resetToDefaults = () => {
    if (
      confirm(
        "Are you sure you want to reset all billing configuration to defaults? This cannot be undone.",
      )
    ) {
      router.post("/admin/billing_configuration/reset");
    }
  };

  const formatDate = (date) => {
    return new Date(date).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  const formatDateTime = (datetime) => {
    return new Date(datetime).toLocaleString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
    });
  };
</script>

<AdminLayout title="Billing Configuration">
  <div class="space-y-6">
    <!-- Header Section -->
    <div class="flex justify-between items-start">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">Billing Configuration</h1>
        <p class="text-gray-600 mt-2">
          Manage system-wide billing settings, automation rules, and reminder
          policies
        </p>
        {#if config.updated_at}
          <p class="text-sm text-gray-500 mt-1">
            Last updated: {formatDateTime(config.updated_at)}
          </p>
        {/if}
      </div>
      <div class="flex space-x-3">
        <Button
          href="/admin/billing_configuration/edit"
          variant="default"
          class="bg-blue-600 hover:bg-blue-700"
        >
          ✏️ Edit Configuration
        </Button>
        <Button onclick={resetToDefaults} variant="destructive" size="sm">
          🔄 Reset to Defaults
        </Button>
      </div>
    </div>

    <!-- Alert Messages -->
    {#if validation_errors && validation_errors.length > 0}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4">
        <div class="flex">
          <div class="ml-3">
            <h3 class="text-sm font-medium text-red-800">
              Configuration Issues
            </h3>
            <div class="mt-2 text-sm text-red-700">
              <ul class="list-disc pl-5 space-y-1">
                {#each validation_errors as error}
                  <li>{error.message}</li>
                {/each}
              </ul>
            </div>
          </div>
        </div>
      </div>
    {/if}

    <!-- Main Configuration Grid -->
    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <!-- Cycle Generation Settings -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center space-x-2">
            <span>🔄</span>
            <span>Cycle Generation</span>
            <Badge
              variant={config.auto_generation_enabled ? "default" : "secondary"}
            >
              {config.auto_generation_enabled ? "Auto" : "Manual"}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-gray-600"
                >Months Ahead</label
              >
              <p class="text-lg font-semibold">
                {config.generation_months_ahead}
              </p>
              <p class="text-xs text-gray-500">
                Generate cycles this far in advance
              </p>
            </div>
            <div>
              <label class="text-sm font-medium text-gray-600"
                >Auto Generation</label
              >
              <p class="text-lg font-semibold">
                {config.auto_generation_enabled ? "Enabled" : "Disabled"}
              </p>
              <p class="text-xs text-gray-500">Automatic cycle creation</p>
            </div>
          </div>

          {#if preview_data}
            <div class="bg-blue-50 p-3 rounded-lg">
              <p class="text-sm font-medium text-blue-800">Current Impact</p>
              <p class="text-sm text-blue-700">
                Generating cycles until: {formatDate(
                  preview_data.generation_end_date,
                )}
              </p>
            </div>
          {/if}
        </CardContent>
      </Card>

      <!-- Archiving Settings -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center space-x-2">
            <span>🗄️</span>
            <span>Cycle Archiving</span>
            <Badge
              variant={config.auto_archiving_enabled ? "default" : "secondary"}
            >
              {config.auto_archiving_enabled ? "Auto" : "Manual"}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-gray-600"
                >Archive Threshold</label
              >
              <p class="text-lg font-semibold">
                {config.archiving_months_threshold} months
              </p>
              <p class="text-xs text-gray-500">
                Archive cycles older than this
              </p>
            </div>
            <div>
              <label class="text-sm font-medium text-gray-600"
                >Auto Archiving</label
              >
              <p class="text-lg font-semibold">
                {config.auto_archiving_enabled ? "Enabled" : "Disabled"}
              </p>
              <p class="text-xs text-gray-500">Automatic cycle archiving</p>
            </div>
          </div>

          {#if preview_data && !loading_preview}
            <div class="bg-yellow-50 p-3 rounded-lg">
              <p class="text-sm font-medium text-yellow-800">
                Archivable Cycles
              </p>
              <p class="text-sm text-yellow-700">
                {preview_data.affected_cycles_count.archivable_cycles} cycles ready
                for archiving
              </p>
            </div>
          {/if}
        </CardContent>
      </Card>

      <!-- Reminder Settings -->
      <Card class="lg:col-span-2">
        <CardHeader>
          <CardTitle class="flex items-center space-x-2">
            <span>📧</span>
            <span>Reminder System</span>
            <Badge variant={config.reminders_enabled ? "default" : "secondary"}>
              {config.reminders_enabled ? "Active" : "Disabled"}
            </Badge>
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div>
              <label class="text-sm font-medium text-gray-600"
                >Gentle Reminder</label
              >
              <p class="text-lg font-semibold">
                {config.gentle_reminder_days_before} days before
              </p>
              <p class="text-xs text-gray-500">First reminder</p>
            </div>
            <div>
              <label class="text-sm font-medium text-gray-600">Standard</label>
              <p class="text-lg font-semibold">
                {config.standard_reminder_days_overdue} days overdue
              </p>
              <p class="text-xs text-gray-500">Follow-up reminder</p>
            </div>
            <div>
              <label class="text-sm font-medium text-gray-600">Urgent</label>
              <p class="text-lg font-semibold">
                {config.urgent_reminder_days_overdue} days overdue
              </p>
              <p class="text-xs text-gray-500">Urgent escalation</p>
            </div>
            <div>
              <label class="text-sm font-medium text-gray-600"
                >Final Notice</label
              >
              <p class="text-lg font-semibold">
                {config.final_notice_days_overdue} days overdue
              </p>
              <p class="text-xs text-gray-500">Last warning</p>
            </div>
          </div>

          <Separator />

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-gray-600"
                >Legacy Schedule</label
              >
              <div class="flex space-x-2 mt-1">
                {#each config.reminder_schedule as days}
                  <Badge variant="outline">{days} days</Badge>
                {/each}
              </div>
              <p class="text-xs text-gray-500 mt-1">Backward compatibility</p>
            </div>
            <div>
              <label class="text-sm font-medium text-gray-600"
                >Grace Period</label
              >
              <p class="text-lg font-semibold">
                {config.payment_grace_period_days} days
              </p>
              <p class="text-xs text-gray-500">Late payment tolerance</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- Billing Frequencies -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center space-x-2">
            <span>📅</span>
            <span>Billing Frequencies</span>
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div>
            <label class="text-sm font-medium text-gray-600"
              >Default Frequency</label
            >
            <p class="text-lg font-semibold capitalize">
              {config.default_frequency}
            </p>
            <p class="text-xs text-gray-500">New projects default to this</p>
          </div>

          <Separator />

          <div>
            <label class="text-sm font-medium text-gray-600"
              >Supported Frequencies</label
            >
            <div class="flex flex-wrap gap-2 mt-2">
              {#each config.supported_billing_frequencies as freq}
                <Badge variant="outline" class="capitalize">
                  {freq}
                </Badge>
              {/each}
            </div>
          </div>

          <div>
            <label class="text-sm font-medium text-gray-600"
              >Default Frequencies</label
            >
            <div class="flex flex-wrap gap-2 mt-2">
              {#each config.default_billing_frequencies as freq}
                <Badge variant="default" class="capitalize">
                  {freq}
                </Badge>
              {/each}
            </div>
          </div>
        </CardContent>
      </Card>

      <!-- System Status -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center space-x-2">
            <span>📊</span>
            <span>System Status</span>
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div>
            <label class="text-sm font-medium text-gray-600"
              >Due Soon Threshold</label
            >
            <p class="text-lg font-semibold">{config.due_soon_days} days</p>
            <p class="text-xs text-gray-500">Cycles approaching due date</p>
          </div>

          {#if preview_data && !loading_preview}
            <Separator />
            <div class="space-y-3">
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Total Cycles</span>
                <Badge variant="outline"
                  >{preview_data.affected_cycles_count.total_cycles}</Badge
                >
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Due Soon</span>
                <Badge variant="secondary"
                  >{preview_data.affected_cycles_count.due_soon_cycles}</Badge
                >
              </div>
              <div class="flex justify-between items-center">
                <span class="text-sm text-gray-600">Ready to Archive</span>
                <Badge variant="outline"
                  >{preview_data.affected_cycles_count.archivable_cycles}</Badge
                >
              </div>
            </div>
          {:else if loading_preview}
            <div class="animate-pulse">
              <div class="h-4 bg-gray-200 rounded w-3/4 mb-2"></div>
              <div class="h-4 bg-gray-200 rounded w-1/2"></div>
            </div>
          {/if}
        </CardContent>
      </Card>
    </div>

    <!-- Configuration History/Metadata -->
    <Card>
      <CardHeader>
        <CardTitle class="flex items-center space-x-2">
          <span>🕒</span>
          <span>Configuration Metadata</span>
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div class="grid grid-cols-2 md:grid-cols-3 gap-4 text-sm">
          <div>
            <label class="font-medium text-gray-600">Configuration ID</label>
            <p class="text-gray-900">#{config.id}</p>
          </div>
          <div>
            <label class="font-medium text-gray-600">Created</label>
            <p class="text-gray-900">{formatDateTime(config.created_at)}</p>
          </div>
          <div>
            <label class="font-medium text-gray-600">Last Modified</label>
            <p class="text-gray-900">{formatDateTime(config.updated_at)}</p>
          </div>
        </div>
      </CardContent>
    </Card>
  </div>
</AdminLayout>
