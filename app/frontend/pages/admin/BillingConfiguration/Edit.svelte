<script>
  import AdminLayout from "../../../layouts/admin-layout.svelte";
  import { Button } from "../../../lib/components/ui/button";
  import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
  } from "../../../lib/components/ui/card";
  import { Input } from "../../../lib/components/ui/input";
  import { Label } from "../../../lib/components/ui/label";
  import { Checkbox } from "../../../lib/components/ui/checkbox";
  import {
    Select,
    SelectContent,
    SelectItem,
    SelectTrigger,
    SelectValue,
  } from "../../../lib/components/ui/select";
  import { Badge } from "../../../lib/components/ui/badge";
  import { Separator } from "../../../lib/components/ui/separator";
  import { router } from "@inertiajs/svelte";
  import { createEventDispatcher } from "svelte";

  export let config;
  export let supported_frequencies;
  export let frequency_descriptions;
  export let validation_errors = [];

  const dispatch = createEventDispatcher();

  // Form data bound to input fields
  let form_data = {
    generation_months_ahead: config.generation_months_ahead,
    archiving_months_threshold: config.archiving_months_threshold,
    due_soon_days: config.due_soon_days,
    auto_archiving_enabled: config.auto_archiving_enabled,
    auto_generation_enabled: config.auto_generation_enabled,
    payment_grace_period_days: config.payment_grace_period_days,
    reminders_enabled: config.reminders_enabled,
    gentle_reminder_days_before: config.gentle_reminder_days_before,
    standard_reminder_days_overdue: config.standard_reminder_days_overdue,
    urgent_reminder_days_overdue: config.urgent_reminder_days_overdue,
    final_notice_days_overdue: config.final_notice_days_overdue,
    default_frequency: config.default_frequency,
    default_billing_frequencies: [...config.default_billing_frequencies],
    supported_billing_frequencies: [...config.supported_billing_frequencies],
    reminder_schedule: [...config.reminder_schedule],
  };

  let validation_warnings = [];
  let is_validating = false;
  let has_unsaved_changes = false;

  // Track changes
  $: {
    has_unsaved_changes =
      JSON.stringify(form_data) !==
      JSON.stringify({
        generation_months_ahead: config.generation_months_ahead,
        archiving_months_threshold: config.archiving_months_threshold,
        due_soon_days: config.due_soon_days,
        auto_archiving_enabled: config.auto_archiving_enabled,
        auto_generation_enabled: config.auto_generation_enabled,
        payment_grace_period_days: config.payment_grace_period_days,
        reminders_enabled: config.reminders_enabled,
        gentle_reminder_days_before: config.gentle_reminder_days_before,
        standard_reminder_days_overdue: config.standard_reminder_days_overdue,
        urgent_reminder_days_overdue: config.urgent_reminder_days_overdue,
        final_notice_days_overdue: config.final_notice_days_overdue,
        default_frequency: config.default_frequency,
        default_billing_frequencies: config.default_billing_frequencies,
        supported_billing_frequencies: config.supported_billing_frequencies,
        reminder_schedule: config.reminder_schedule,
      });
  }

  // Real-time validation
  const validateForm = async () => {
    if (is_validating) return;

    is_validating = true;
    try {
      const response = await fetch(
        "/admin/billing_configuration/validate_config",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document
              .querySelector('meta[name="csrf-token"]')
              ?.getAttribute("content"),
          },
          body: JSON.stringify({ billing_config: form_data }),
        },
      );

      const result = await response.json();
      validation_warnings = result.warnings || [];
    } catch (error) {
      console.error("Validation failed:", error);
    } finally {
      is_validating = false;
    }
  };

  // Submit form
  const handleSubmit = () => {
    router.put("/admin/billing_configuration", {
      billing_config: form_data,
    });
  };

  // Array management helpers
  const addToArray = (arrayName, value) => {
    if (value && !form_data[arrayName].includes(value)) {
      form_data[arrayName] = [...form_data[arrayName], value];
      validateForm();
    }
  };

  const removeFromArray = (arrayName, value) => {
    form_data[arrayName] = form_data[arrayName].filter(
      (item) => item !== value,
    );
    validateForm();
  };

  const updateReminderSchedule = (index, value) => {
    const newSchedule = [...form_data.reminder_schedule];
    newSchedule[index] = parseInt(value) || 0;
    form_data.reminder_schedule = newSchedule;
    validateForm();
  };

  const addReminderDay = () => {
    form_data.reminder_schedule = [...form_data.reminder_schedule, 7];
    validateForm();
  };

  const removeReminderDay = (index) => {
    form_data.reminder_schedule = form_data.reminder_schedule.filter(
      (_, i) => i !== index,
    );
    validateForm();
  };

  // Get error for specific field
  const getFieldError = (field_name) => {
    return validation_errors.find((error) => error.field === field_name)
      ?.message;
  };

  // Validate form on data changes (debounced)
  let validation_timeout;
  $: {
    if (has_unsaved_changes) {
      clearTimeout(validation_timeout);
      validation_timeout = setTimeout(validateForm, 500);
    }
  }
</script>

<AdminLayout title="Edit Billing Configuration">
  <div class="space-y-6">
    <!-- Header Section -->
    <div class="flex justify-between items-start">
      <div>
        <h1 class="text-3xl font-bold text-gray-900">
          Edit Billing Configuration
        </h1>
        <p class="text-gray-600 mt-2">
          Modify system-wide billing settings. Changes affect all users and
          projects.
        </p>
        {#if has_unsaved_changes}
          <p class="text-amber-600 text-sm mt-1 font-medium">
            ⚠️ You have unsaved changes
          </p>
        {/if}
      </div>
      <div class="flex space-x-3">
        <Button href="/admin/billing_configuration" variant="outline">
          Cancel
        </Button>
        <Button
          on:click={handleSubmit}
          variant="default"
          class="bg-blue-600 hover:bg-blue-700"
          disabled={!has_unsaved_changes}
        >
          💾 Save Configuration
        </Button>
      </div>
    </div>

    <!-- Validation Alerts -->
    {#if validation_errors && validation_errors.length > 0}
      <div class="bg-red-50 border border-red-200 rounded-lg p-4">
        <div class="flex">
          <div class="ml-3">
            <h3 class="text-sm font-medium text-red-800">Validation Errors</h3>
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

    {#if validation_warnings && validation_warnings.length > 0}
      <div class="bg-amber-50 border border-amber-200 rounded-lg p-4">
        <div class="flex">
          <div class="ml-3">
            <h3 class="text-sm font-medium text-amber-800">
              Configuration Warnings
            </h3>
            <div class="mt-2 text-sm text-amber-700">
              <ul class="list-disc pl-5 space-y-1">
                {#each validation_warnings as warning}
                  <li>{warning}</li>
                {/each}
              </ul>
            </div>
          </div>
        </div>
      </div>
    {/if}

    <!-- Form Content -->
    <form on:submit|preventDefault={handleSubmit} class="space-y-6">
      <!-- Cycle Generation Settings -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center space-x-2">
            <span>🔄</span>
            <span>Cycle Generation Settings</span>
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label for="generation_months_ahead">Months Ahead</Label>
              <Input
                id="generation_months_ahead"
                type="number"
                min="1"
                max="12"
                bind:value={form_data.generation_months_ahead}
                class={getFieldError("generation_months_ahead")
                  ? "border-red-500"
                  : ""}
              />
              {#if getFieldError("generation_months_ahead")}
                <p class="text-sm text-red-600">
                  {getFieldError("generation_months_ahead")}
                </p>
              {/if}
              <p class="text-xs text-gray-500">
                How many months ahead to generate billing cycles
              </p>
            </div>

            <div class="space-y-2">
              <Label for="due_soon_days">Due Soon Threshold (Days)</Label>
              <Input
                id="due_soon_days"
                type="number"
                min="1"
                max="30"
                bind:value={form_data.due_soon_days}
                class={getFieldError("due_soon_days") ? "border-red-500" : ""}
              />
              {#if getFieldError("due_soon_days")}
                <p class="text-sm text-red-600">
                  {getFieldError("due_soon_days")}
                </p>
              {/if}
              <p class="text-xs text-gray-500">
                Days before due date to mark cycles as "due soon"
              </p>
            </div>
          </div>

          <div class="flex items-center space-x-2">
            <Checkbox
              id="auto_generation_enabled"
              bind:checked={form_data.auto_generation_enabled}
            />
            <Label for="auto_generation_enabled"
              >Enable automatic cycle generation</Label
            >
          </div>
        </CardContent>
      </Card>

      <!-- Archiving Settings -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center space-x-2">
            <span>🗄️</span>
            <span>Cycle Archiving Settings</span>
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="space-y-2">
              <Label for="archiving_months_threshold"
                >Archive Threshold (Months)</Label
              >
              <Input
                id="archiving_months_threshold"
                type="number"
                min="1"
                max="24"
                bind:value={form_data.archiving_months_threshold}
                class={getFieldError("archiving_months_threshold")
                  ? "border-red-500"
                  : ""}
              />
              {#if getFieldError("archiving_months_threshold")}
                <p class="text-sm text-red-600">
                  {getFieldError("archiving_months_threshold")}
                </p>
              {/if}
              <p class="text-xs text-gray-500">
                Archive cycles older than this many months
              </p>
            </div>

            <div class="space-y-2">
              <Label for="payment_grace_period_days"
                >Payment Grace Period (Days)</Label
              >
              <Input
                id="payment_grace_period_days"
                type="number"
                min="0"
                max="30"
                bind:value={form_data.payment_grace_period_days}
                class={getFieldError("payment_grace_period_days")
                  ? "border-red-500"
                  : ""}
              />
              {#if getFieldError("payment_grace_period_days")}
                <p class="text-sm text-red-600">
                  {getFieldError("payment_grace_period_days")}
                </p>
              {/if}
              <p class="text-xs text-gray-500">
                Extra days allowed for late payments
              </p>
            </div>
          </div>

          <div class="flex items-center space-x-2">
            <Checkbox
              id="auto_archiving_enabled"
              bind:checked={form_data.auto_archiving_enabled}
            />
            <Label for="auto_archiving_enabled"
              >Enable automatic cycle archiving</Label
            >
          </div>
        </CardContent>
      </Card>

      <!-- Reminder Settings -->
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center space-x-2">
            <span>📧</span>
            <span>Reminder System</span>
          </CardTitle>
        </CardHeader>
        <CardContent class="space-y-6">
          <div class="flex items-center space-x-2">
            <Checkbox
              id="reminders_enabled"
              bind:checked={form_data.reminders_enabled}
            />
            <Label for="reminders_enabled">Enable reminder system</Label>
          </div>

          {#if form_data.reminders_enabled}
            <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div class="space-y-2">
                <Label for="gentle_reminder_days_before"
                  >Gentle Reminder (Days Before)</Label
                >
                <Input
                  id="gentle_reminder_days_before"
                  type="number"
                  min="1"
                  max="30"
                  bind:value={form_data.gentle_reminder_days_before}
                  class={getFieldError("gentle_reminder_days_before")
                    ? "border-red-500"
                    : ""}
                />
                <p class="text-xs text-gray-500">First reminder before due</p>
              </div>

              <div class="space-y-2">
                <Label for="standard_reminder_days_overdue"
                  >Standard (Days Overdue)</Label
                >
                <Input
                  id="standard_reminder_days_overdue"
                  type="number"
                  min="0"
                  max="30"
                  bind:value={form_data.standard_reminder_days_overdue}
                  class={getFieldError("standard_reminder_days_overdue")
                    ? "border-red-500"
                    : ""}
                />
                <p class="text-xs text-gray-500">Follow-up reminder</p>
              </div>

              <div class="space-y-2">
                <Label for="urgent_reminder_days_overdue"
                  >Urgent (Days Overdue)</Label
                >
                <Input
                  id="urgent_reminder_days_overdue"
                  type="number"
                  min="0"
                  max="30"
                  bind:value={form_data.urgent_reminder_days_overdue}
                  class={getFieldError("urgent_reminder_days_overdue")
                    ? "border-red-500"
                    : ""}
                />
                <p class="text-xs text-gray-500">Urgent escalation</p>
              </div>

              <div class="space-y-2">
                <Label for="final_notice_days_overdue"
                  >Final Notice (Days Overdue)</Label
                >
                <Input
                  id="final_notice_days_overdue"
                  type="number"
                  min="0"
                  max="30"
                  bind:value={form_data.final_notice_days_overdue}
                  class={getFieldError("final_notice_days_overdue")
                    ? "border-red-500"
                    : ""}
                />
                <p class="text-xs text-gray-500">Final warning</p>
              </div>
            </div>

            <Separator />

            <!-- Legacy Reminder Schedule -->
            <div class="space-y-3">
              <Label>Legacy Reminder Schedule (Days Before Due)</Label>
              <div class="flex flex-wrap gap-2">
                {#each form_data.reminder_schedule as days, index}
                  <div
                    class="flex items-center space-x-1 bg-gray-50 rounded-lg p-2"
                  >
                    <Input
                      type="number"
                      min="1"
                      max="30"
                      value={days}
                      on:input={(e) =>
                        updateReminderSchedule(index, e.target.value)}
                      class="w-16 text-sm"
                    />
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      on:click={() => removeReminderDay(index)}
                      class="text-red-600 hover:text-red-700 p-1"
                    >
                      ✕
                    </Button>
                  </div>
                {/each}
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  on:click={addReminderDay}
                  class="text-blue-600 hover:text-blue-700"
                >
                  + Add Day
                </Button>
              </div>
              <p class="text-xs text-gray-500">
                Backward compatibility for older projects
              </p>
            </div>
          {/if}
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
          <div class="space-y-2">
            <Label for="default_frequency">Default Frequency</Label>
            <Select bind:value={form_data.default_frequency}>
              <SelectTrigger>
                <SelectValue placeholder="Select default frequency" />
              </SelectTrigger>
              <SelectContent>
                {#each supported_frequencies as freq}
                  <SelectItem value={freq.value}>
                    {freq.label} - {freq.description}
                  </SelectItem>
                {/each}
              </SelectContent>
            </Select>
            <p class="text-xs text-gray-500">
              Default billing frequency for new projects
            </p>
          </div>

          <Separator />

          <div class="space-y-3">
            <Label>Supported Billing Frequencies</Label>
            <div class="space-y-2">
              {#each supported_frequencies as freq}
                <div
                  class="flex items-center justify-between p-3 border rounded-lg"
                >
                  <div>
                    <div class="flex items-center space-x-2">
                      <Checkbox
                        checked={form_data.supported_billing_frequencies.includes(
                          freq.value,
                        )}
                        on:change={(e) => {
                          if (e.target.checked) {
                            addToArray(
                              "supported_billing_frequencies",
                              freq.value,
                            );
                          } else {
                            removeFromArray(
                              "supported_billing_frequencies",
                              freq.value,
                            );
                          }
                        }}
                      />
                      <span class="font-medium capitalize">{freq.label}</span>
                    </div>
                    <p class="text-sm text-gray-500 ml-6">
                      {frequency_descriptions[freq.value]}
                    </p>
                  </div>
                  {#if form_data.supported_billing_frequencies.includes(freq.value)}
                    <Badge variant="outline">Enabled</Badge>
                  {/if}
                </div>
              {/each}
            </div>
          </div>

          <Separator />

          <div class="space-y-3">
            <Label>Default Billing Frequencies (Offered to New Users)</Label>
            <div class="space-y-2">
              {#each supported_frequencies as freq}
                {#if form_data.supported_billing_frequencies.includes(freq.value)}
                  <div
                    class="flex items-center justify-between p-3 border rounded-lg"
                  >
                    <div>
                      <div class="flex items-center space-x-2">
                        <Checkbox
                          checked={form_data.default_billing_frequencies.includes(
                            freq.value,
                          )}
                          on:change={(e) => {
                            if (e.target.checked) {
                              addToArray(
                                "default_billing_frequencies",
                                freq.value,
                              );
                            } else {
                              removeFromArray(
                                "default_billing_frequencies",
                                freq.value,
                              );
                            }
                          }}
                        />
                        <span class="font-medium capitalize">{freq.label}</span>
                      </div>
                      <p class="text-sm text-gray-500 ml-6">
                        {freq.description}
                      </p>
                    </div>
                    {#if form_data.default_billing_frequencies.includes(freq.value)}
                      <Badge variant="default">Default Option</Badge>
                    {/if}
                  </div>
                {/if}
              {/each}
            </div>
            <p class="text-xs text-gray-500">
              These frequencies will be pre-selected for new users
            </p>
          </div>
        </CardContent>
      </Card>

      <!-- Form Actions -->
      <div class="flex justify-between items-center pt-6 border-t">
        <Button
          type="button"
          href="/admin/billing_configuration"
          variant="outline"
        >
          Cancel Changes
        </Button>
        <div class="space-x-3">
          <Button
            type="button"
            variant="secondary"
            disabled={!has_unsaved_changes || is_validating}
            on:click={validateForm}
          >
            {is_validating ? "⏳ Validating..." : "🔍 Validate"}
          </Button>
          <Button
            type="submit"
            variant="default"
            class="bg-blue-600 hover:bg-blue-700"
            disabled={!has_unsaved_changes}
          >
            💾 Save Configuration
          </Button>
        </div>
      </div>
    </form>
  </div>
</AdminLayout>
