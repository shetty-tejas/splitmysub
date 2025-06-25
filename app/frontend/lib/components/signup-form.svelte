<script>
  import { Button } from "$lib/components/ui/button/index.js";
  import * as Card from "$lib/components/ui/card/index.js";
  import { Input } from "$lib/components/ui/input/index.js";
  import { InputError } from "$lib/components/ui/input-error/index.js";
  import { Label } from "$lib/components/ui/label/index.js";
  import { Link, useForm } from "@inertiajs/svelte";
  import { signupPath, loginPath } from "@/routes";
  import { onMount } from "svelte";

  const form = useForm({
    email_address: "",
    first_name: "",
    last_name: "",
    "cf-turnstile-response": "",
  });

  let turnstileWidget;
  let turnstileWidgetId;
  let turnstileCallback;

  onMount(() => {
    // Validate site key availability
    if (!window.CLOUDFLARE_TURNSTILE_SITE_KEY) {
      console.error("Turnstile site key is not available");
      return;
    }

    // Set up the Turnstile callback function
    turnstileCallback = (token) => {
      $form["cf-turnstile-response"] = token;
    };

    // Function to initialize Turnstile widget
    const initializeTurnstile = () => {
      if (
        window.turnstile &&
        turnstileWidget &&
        !turnstileWidgetId &&
        window.CLOUDFLARE_TURNSTILE_SITE_KEY
      ) {
        try {
          turnstileWidgetId = window.turnstile.render(turnstileWidget, {
            sitekey: window.CLOUDFLARE_TURNSTILE_SITE_KEY,
            callback: turnstileCallback,
            theme: "light",
            size: "normal",
          });
        } catch (error) {
          console.error("Failed to render Turnstile widget:", error);
        }
      }
    };

    // Check if Turnstile is already loaded
    if (window.turnstile) {
      initializeTurnstile();
    } else {
      // Poll for Turnstile to be available
      const checkTurnstile = setInterval(() => {
        if (window.turnstile) {
          clearInterval(checkTurnstile);
          initializeTurnstile();
        }
      }, 100);

      // Clear interval after 10 seconds to prevent infinite polling
      setTimeout(() => {
        clearInterval(checkTurnstile);
      }, 10000);
    }

    // Cleanup function
    return () => {
      if (window.turnstile && turnstileWidgetId) {
        try {
          window.turnstile.remove(turnstileWidgetId);
        } catch (error) {
          console.error("Failed to remove Turnstile widget:", error);
        }
      }
    };
  });

  function submit(e) {
    e.preventDefault();

    $form.post(signupPath(), {
      onSuccess: () => {
        // Reset all form fields after successful submission
        $form.email_address = "";
        $form.first_name = "";
        $form.last_name = "";
        $form["cf-turnstile-response"] = "";

        // Reset the Turnstile widget
        if (window.turnstile && turnstileWidgetId) {
          try {
            window.turnstile.reset(turnstileWidgetId);
          } catch (error) {
            console.error("Failed to reset Turnstile widget:", error);
          }
        }
      },
      onError: () => {
        // Reset the Turnstile widget on error
        if (window.turnstile && turnstileWidgetId) {
          try {
            window.turnstile.reset(turnstileWidgetId);
          } catch (error) {
            console.error("Failed to reset Turnstile widget:", error);
          }
        }
      },
    });
  }
</script>

<Card.Root class="mx-auto max-w-sm w-full">
  <Card.Header>
    <Card.Title class="text-2xl">Sign up</Card.Title>
    <Card.Description>Create your account to get started</Card.Description>
  </Card.Header>
  <Card.Content>
    <form onsubmit={submit}>
      <div class="grid gap-4">
        <div class="grid grid-cols-2 gap-4">
          <div class="grid gap-2">
            <Label for="first_name">First name</Label>
            <Input
              id="first_name"
              type="text"
              placeholder="John"
              required
              bind:value={$form.first_name}
            />
            <InputError errors={$form.errors.first_name} />
          </div>
          <div class="grid gap-2">
            <Label for="last_name">Last name</Label>
            <Input
              id="last_name"
              type="text"
              placeholder="Doe"
              required
              bind:value={$form.last_name}
            />
            <InputError errors={$form.errors.last_name} />
          </div>
        </div>
        <div class="grid gap-2">
          <Label for="email_address">Email</Label>
          <Input
            id="email_address"
            type="email"
            placeholder="m@example.com"
            required
            bind:value={$form.email_address}
          />
          <InputError errors={$form.errors.email_address} />
        </div>

        <!-- Cloudflare Turnstile Widget -->
        <div class="grid gap-2">
          <div class="flex justify-center" bind:this={turnstileWidget}></div>
          <InputError errors={$form.errors["cf-turnstile-response"]} />
        </div>

        <Button type="submit" class="w-full" disabled={$form.processing}>
          {$form.processing ? "Creating account..." : "Create Account"}
        </Button>
      </div>
    </form>
    <div class="mt-4 text-center text-sm text-muted-foreground">
      We'll send you a magic link to complete your registration
    </div>
    <div class="mt-4 text-center text-sm">
      Already have an account?
      <Link href={loginPath()} class="underline">Sign in</Link>
    </div>
  </Card.Content>
</Card.Root>
