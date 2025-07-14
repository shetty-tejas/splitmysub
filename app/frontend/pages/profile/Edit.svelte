<script>
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
  import { Input } from "$lib/components/ui/input";
  import { Label } from "$lib/components/ui/label";
  import { Separator } from "$lib/components/ui/separator";
  import { CurrencySelect } from "$lib/components/ui/currency-select";
  import {
    ArrowLeft,
    Save,
    User,
    MessageCircle,
    Link,
    Unlink,
  } from "@lucide/svelte";
  import { onDestroy } from "svelte";
  import { toast } from "svelte-sonner";

  export let user;
  export let currency_options = [];
  export let errors = {};
  export let telegram_verification_token = null;

  let form = {
    first_name: user.first_name || "",
    last_name: user.last_name || "",
    email_address: user.email_address || "",
    preferred_currency: user.preferred_currency || "USD",
  };

  let isSubmitting = false;
  let copyButtonState = "copy"; // "copy", "copying", "copied"
  let pollInterval = null;

  function handleSubmit() {
    isSubmitting = true;

    router.patch(
      "/profile",
      { user: form },
      {
        onSuccess: () => {
          // Will redirect automatically from controller
        },
        onError: (errors) => {
          console.error("Error updating profile:", errors);
          isSubmitting = false;
        },
        onFinish: () => {
          isSubmitting = false;
        },
      },
    );
  }

  function goBack() {
    router.get("/profile");
  }

  async function generateTelegramToken() {
    try {
      const response = await fetch("/profile/telegram/generate_token", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document
            .querySelector('meta[name="csrf-token"]')
            .getAttribute("content"),
        },
      });

      if (response.ok) {
        const data = await response.json();
        telegram_verification_token = data.token;
        startPollingForLinking();
      } else {
        console.error("Error generating Telegram token");
      }
    } catch (error) {
      console.error("Error generating Telegram token:", error);
    }
  }

  function startPollingForLinking() {
    // Clear any existing polling
    if (pollInterval) {
      clearInterval(pollInterval);
    }

    // Poll every 3 seconds for account linking
    pollInterval = setInterval(async () => {
      try {
        const response = await fetch("/profile/telegram/check_status", {
          method: "GET",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": document
              .querySelector('meta[name="csrf-token"]')
              .getAttribute("content"),
          },
        });

        if (response.ok) {
          const data = await response.json();
          if (data.linked) {
            // Account is linked! Show toast and refresh
            clearInterval(pollInterval);
            toast.success("🎉 Telegram account linked successfully!");
            setTimeout(() => {
              window.location.reload();
            }, 1500); // Wait 1.5 seconds to show the toast
          }
        }
      } catch (error) {
        console.error("Error checking Telegram status:", error);
      }
    }, 3000); // Check every 3 seconds

    // Stop polling after 15 minutes (token expiration)
    setTimeout(
      () => {
        if (pollInterval) {
          clearInterval(pollInterval);
          pollInterval = null;
        }
      },
      15 * 60 * 1000,
    );
  }

  function unlinkTelegram() {
    if (confirm("Are you sure you want to unlink your Telegram account?")) {
      router.delete(
        "/profile/telegram/unlink",
        {},
        {
          onSuccess: () => {
            user.telegram_user_id = null;
            user.telegram_username = null;
            user.telegram_notifications_enabled = true;
          },
          onError: (errors) => {
            console.error("Error unlinking Telegram:", errors);
          },
        },
      );
    }
  }

  function toggleTelegramNotifications() {
    router.patch(
      "/profile/telegram/toggle_notifications",
      {},
      {
        onSuccess: (page) => {
          user.telegram_notifications_enabled =
            page.props.user.telegram_notifications_enabled;
        },
        onError: (errors) => {
          console.error("Error toggling Telegram notifications:", errors);
        },
      },
    );
  }

  // Cleanup polling on component destroy
  onDestroy(() => {
    if (pollInterval) {
      clearInterval(pollInterval);
    }
  });

  function copyToClipboard(text) {
    copyButtonState = "copying";

    navigator.clipboard
      .writeText(text)
      .then(() => {
        copyButtonState = "copied";
        toast.success("📋 Command copied to clipboard!");
        setTimeout(() => {
          copyButtonState = "copy";
        }, 2000); // Reset after 2 seconds
      })
      .catch((err) => {
        console.error("Failed to copy text: ", err);
        // Fallback for older browsers
        try {
          const textArea = document.createElement("textarea");
          textArea.value = text;
          document.body.appendChild(textArea);
          textArea.select();
          document.execCommand("copy");
          document.body.removeChild(textArea);

          copyButtonState = "copied";
          toast.success("📋 Command copied to clipboard!");
          setTimeout(() => {
            copyButtonState = "copy";
          }, 2000);
        } catch (fallbackErr) {
          console.error("Fallback copy failed: ", fallbackErr);
          copyButtonState = "copy";
        }
      });
  }
</script>

<svelte:head>
  <title>Edit Profile - SplitMySub</title>
</svelte:head>

<Layout>
  <div class="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
    <div class="flex items-center gap-4 mb-8">
      <button
        type="button"
        onclick={goBack}
        onkeydown={(e) => (e.key === "Enter" || e.key === " ") && goBack}
        class="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-muted-foreground hover:text-foreground hover:bg-accent hover:bg-opacity-50 rounded-md transition-colors cursor-pointer"
      >
        <ArrowLeft class="h-4 w-4" />
        Back to Profile
      </button>
    </div>

    <div class="mx-auto max-w-2xl">
      <Card>
        <CardHeader>
          <CardTitle class="flex items-center gap-2 text-2xl">
            <User class="h-6 w-6" />
            Edit Profile
          </CardTitle>
          <CardDescription>
            Update your personal information and account details
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form
            onsubmit={(e) => {
              e.preventDefault();
              handleSubmit(e);
            }}
            class="space-y-6"
          >
            <!-- Personal Information -->
            <div class="space-y-4">
              <h3 class="text-lg font-semibold">Personal Information</h3>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="space-y-2">
                  <Label for="first_name">First Name *</Label>
                  <Input
                    id="first_name"
                    bind:value={form.first_name}
                    placeholder="Enter your first name"
                    class={errors.first_name ? "border-destructive" : ""}
                    required
                  />
                  {#if errors.first_name}
                    <p class="text-sm text-destructive">
                      {errors.first_name[0]}
                    </p>
                  {/if}
                </div>

                <div class="space-y-2">
                  <Label for="last_name">Last Name *</Label>
                  <Input
                    id="last_name"
                    bind:value={form.last_name}
                    placeholder="Enter your last name"
                    class={errors.last_name ? "border-destructive" : ""}
                    required
                  />
                  {#if errors.last_name}
                    <p class="text-sm text-destructive">
                      {errors.last_name[0]}
                    </p>
                  {/if}
                </div>
              </div>
            </div>

            <Separator />

            <!-- Currency Preferences -->
            <div class="space-y-4">
              <h3 class="text-lg font-semibold">Currency Preferences</h3>

              <div class="space-y-2">
                <Label for="preferred_currency">Preferred Currency *</Label>
                <CurrencySelect
                  bind:value={form.preferred_currency}
                  currencyOptions={currency_options}
                  placeholder="Select your preferred currency"
                  className={errors.preferred_currency
                    ? "border-destructive"
                    : ""}
                />
                {#if errors.preferred_currency}
                  <p class="text-sm text-destructive">
                    {errors.preferred_currency[0]}
                  </p>
                {/if}
                <p class="text-sm text-muted-foreground">
                  This currency will be used as the default for new projects you
                  create.
                </p>
              </div>
            </div>

            <Separator />

            <!-- Account Information -->
            <div class="space-y-4">
              <h3 class="text-lg font-semibold">Account Information</h3>

              <div class="space-y-2">
                <Label for="email_address">Email Address *</Label>
                <Input
                  id="email_address"
                  type="email"
                  bind:value={form.email_address}
                  placeholder="Enter your email address"
                  class={errors.email_address ? "border-destructive" : ""}
                  required
                />
                {#if errors.email_address}
                  <p class="text-sm text-destructive">
                    {errors.email_address[0]}
                  </p>
                {/if}
                <p class="text-sm text-muted-foreground">
                  This email will be used for login and notifications about your
                  projects.
                </p>
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
                <!-- Linked Account -->
                <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                  <div class="flex items-center justify-between">
                    <div>
                      <p class="text-sm font-medium text-green-800">
                        ✅ Account Linked
                      </p>
                      <p class="text-sm text-green-600">
                        Connected to: @{user.telegram_username || "Unknown"}
                      </p>
                    </div>
                    <Button
                      type="button"
                      variant="outline"
                      size="sm"
                      onclick={unlinkTelegram}
                      class="text-red-600 hover:text-red-700 border-red-200 hover:border-red-300"
                    >
                      <Unlink class="h-4 w-4 mr-2" />
                      Unlink
                    </Button>
                  </div>
                </div>

                <!-- Notification Settings -->
                <div class="space-y-3">
                  <Label>Notification Preferences</Label>
                  <div
                    class="flex items-center justify-between p-3 border rounded-lg"
                  >
                    <div>
                      <p class="text-sm font-medium">Telegram Notifications</p>
                      <p class="text-sm text-muted-foreground">
                        Receive payment reminders and updates via Telegram
                      </p>
                    </div>
                    <Button
                      type="button"
                      variant={user.telegram_notifications_enabled
                        ? "default"
                        : "outline"}
                      size="sm"
                      onclick={toggleTelegramNotifications}
                    >
                      {user.telegram_notifications_enabled
                        ? "Enabled"
                        : "Disabled"}
                    </Button>
                  </div>
                </div>
              {:else}
                <!-- Not Linked -->
                <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                  <div class="space-y-4">
                    <div>
                      <p class="text-sm font-medium text-blue-800">
                        📱 Connect Your Telegram Account
                      </p>
                      <p class="text-sm text-blue-600">
                        Get payment reminders and updates directly in Telegram
                      </p>
                    </div>

                    <div class="space-y-3">
                      <Button
                        type="button"
                        variant="outline"
                        onclick={generateTelegramToken}
                        class="text-blue-600 hover:text-blue-700 border-blue-200 hover:border-blue-300"
                      >
                        <Link class="h-4 w-4 mr-2" />
                        Generate Linking Token
                      </Button>

                      {#if telegram_verification_token}
                        <div
                          class="bg-blue-50 border border-blue-200 rounded p-3"
                        >
                          <p class="text-sm font-medium text-blue-800">
                            📋 Verification Token Generated
                          </p>
                          <p class="text-sm text-blue-600 mt-1">
                            Open Telegram and send this message to
                            @SplitMySubBot:
                          </p>
                          <div
                            class="mt-2 p-2 bg-blue-100 rounded font-mono text-sm flex items-center justify-between"
                          >
                            <span>/start {telegram_verification_token}</span>
                            <Button
                              type="button"
                              variant={copyButtonState === "copied"
                                ? "default"
                                : "outline"}
                              size="sm"
                              onclick={() =>
                                copyToClipboard(
                                  `/start ${telegram_verification_token}`,
                                )}
                              disabled={copyButtonState === "copying"}
                              class="ml-2 h-8 px-2 text-xs transition-all duration-200 {copyButtonState ===
                              'copied'
                                ? 'bg-green-600 hover:bg-green-700 text-white border-green-600'
                                : ''}"
                            >
                              {#if copyButtonState === "copying"}
                                <div
                                  class="animate-spin rounded-full h-3 w-3 border-b-2 border-current mr-1"
                                ></div>
                                Copying...
                              {:else if copyButtonState === "copied"}
                                ✅ Copied!
                              {:else}
                                📋 Copy
                              {/if}
                            </Button>
                          </div>
                          <p class="text-sm text-blue-600 mt-2">
                            This token will expire in 15 minutes.
                          </p>
                        </div>
                      {/if}
                    </div>
                  </div>
                </div>
              {/if}
            </div>

            <!-- Submit Buttons -->
            <div class="flex justify-end gap-4 pt-6">
              <Button
                type="button"
                variant="outline"
                onclick={goBack}
                onkeydown={(e) =>
                  (e.key === "Enter" || e.key === " ") && goBack}
                disabled={isSubmitting}
              >
                Cancel
              </Button>
              <Button type="submit" disabled={isSubmitting}>
                {#if isSubmitting}
                  <div
                    class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"
                  ></div>
                {:else}
                  <Save class="h-4 w-4 mr-2" />
                {/if}
                Save Changes
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>
    </div>
  </div>

</Layout>
