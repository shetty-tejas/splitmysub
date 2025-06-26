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
  import { ArrowLeft, Save, User } from "lucide-svelte";

  export let user;
  export let currency_options = [];
  export let errors = {};

  let form = {
    first_name: user.first_name || "",
    last_name: user.last_name || "",
    email_address: user.email_address || "",
    preferred_currency: user.preferred_currency || "USD",
  };

  let isSubmitting = false;

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
