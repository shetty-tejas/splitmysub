<script>
  import { router } from "@inertiajs/svelte";
  import { editProfilePath } from "../../routes/index.js";
  import Layout from "../../layouts/layout.svelte";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Button } from "$lib/components/ui/button";
  import { Separator } from "$lib/components/ui/separator";
  import {
    getCurrencySymbol,
    SUPPORTED_CURRENCIES,
  } from "$lib/currency-utils.js";
  import { Edit, User, Mail, Calendar, DollarSign, MessageCircle } from "@lucide/svelte";

  export let user;

  function formatDate(dateString) {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  }

  function editProfile() {
    router.get(editProfilePath());
  }

  function getCurrencyName(code) {
    return SUPPORTED_CURRENCIES[code]?.name || code;
  }
</script>

<svelte:head>
  <title>Profile - SplitMySub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <div class="mx-auto max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2 text-2xl">
            <User class="h-6 w-6" />
            Personal Information
          </CardTitle>
          <CardDescription>
            Your account details and personal information
          </CardDescription>
        </CardHeader>
        <CardContent class="space-y-6">
          <!-- Personal Details -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">Personal Details</h3>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div class="space-y-2">
                <dt class="text-sm font-medium text-muted-foreground">
                  First Name
                </dt>
                <dd class="text-sm font-medium">{user.first_name}</dd>
              </div>

              <div class="space-y-2">
                <dt class="text-sm font-medium text-muted-foreground">
                  Last Name
                </dt>
                <dd class="text-sm font-medium">{user.last_name}</dd>
              </div>
            </div>

            <div class="space-y-2">
              <dt class="text-sm font-medium text-muted-foreground">
                Full Name
              </dt>
              <dd class="text-sm font-medium">
                {user.first_name}
                {user.last_name}
              </dd>
            </div>
          </div>

          <Separator />

          <!-- Currency Preferences -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">Currency Preferences</h3>

            <div class="space-y-2">
              <dt
                class="text-sm font-medium text-muted-foreground flex items-center gap-2"
              >
                <DollarSign class="h-4 w-4" />
                Preferred Currency
              </dt>
              <dd class="text-sm font-medium flex items-center gap-2">
                <span class="font-mono"
                  >{getCurrencySymbol(user.preferred_currency)}</span
                >
                <span
                  >{user.preferred_currency} - {getCurrencyName(
                    user.preferred_currency,
                  )}</span
                >
              </dd>
            </div>
          </div>

          <Separator />

          <!-- Account Information -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold">Account Information</h3>

            <div class="space-y-2">
              <dt
                class="text-sm font-medium text-muted-foreground flex items-center gap-2"
              >
                <Mail class="h-4 w-4" />
                Email Address
              </dt>
              <dd class="text-sm font-medium">{user.email_address}</dd>
            </div>

            <div class="space-y-2">
              <dt
                class="text-sm font-medium text-muted-foreground flex items-center gap-2"
              >
                <Calendar class="h-4 w-4" />
                Member Since
              </dt>
              <dd class="text-sm font-medium">{formatDate(user.created_at)}</dd>
            </div>
          </div>

          <Separator />

          <!-- Telegram Integration -->
          <div class="space-y-4">
            <h3 class="text-lg font-semibold flex items-center gap-2">
              <MessageCircle class="h-5 w-5" />
              Telegram Integration
            </h3>

            {#if user.telegram_user_id}
              <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                <div class="space-y-2">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-medium text-green-800">
                      ✅ Account Linked
                    </span>
                  </div>
                  <div class="space-y-1">
                    <dt class="text-sm font-medium text-green-700">
                      Connected Account
                    </dt>
                    <dd class="text-sm text-green-600">
                      @{user.telegram_username || "Unknown"}
                    </dd>
                  </div>
                  <div class="space-y-1">
                    <dt class="text-sm font-medium text-green-700">
                      Notifications
                    </dt>
                    <dd class="text-sm text-green-600">
                      {user.telegram_notifications_enabled ? "✅ Enabled" : "🔕 Disabled"}
                    </dd>
                  </div>
                </div>
              </div>
            {:else}
              <div class="bg-gray-50 border border-gray-200 rounded-lg p-4">
                <div class="space-y-2">
                  <div class="flex items-center gap-2">
                    <span class="text-sm font-medium text-gray-600">
                      📱 Not Connected
                    </span>
                  </div>
                  <p class="text-sm text-gray-500">
                    Link your Telegram account to receive payment reminders and manage subscriptions through our bot.
                  </p>
                </div>
              </div>
            {/if}
          </div>

          <!-- Actions -->
          <div class="pt-6">
            <Button
              onclick={editProfile}
              onkeydown={(e) =>
                (e.key === "Enter" || e.key === " ") && editProfile}
              class="w-full sm:w-auto"
            >
              <Edit class="h-4 w-4 mr-2" />
              Edit Profile
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  </div>
</Layout>
