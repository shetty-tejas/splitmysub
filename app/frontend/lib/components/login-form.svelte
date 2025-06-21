<script>
  import { Button } from "$lib/components/ui/button/index.js";
  import * as Card from "$lib/components/ui/card/index.js";
  import { Input } from "$lib/components/ui/input/index.js";
  import { InputError } from "$lib/components/ui/input-error/index.js";
  import { Label } from "$lib/components/ui/label/index.js";
  import { Link, useForm } from "@inertiajs/svelte";
  import { magicLinkPath, signupPath } from "@/routes";

  const form = useForm({
    email_address: "",
  });

  function sendMagicLink(e) {
    e.preventDefault();
    $form.post(magicLinkPath(), {
      onSuccess: () => {
        // Reset the form field after successful submission
        $form.email_address = "";
      },
    });
  }
</script>

<Card.Root class="mx-auto max-w-sm w-full">
  <Card.Header>
    <Card.Title class="text-2xl">Sign in</Card.Title>
    <Card.Description>
      Enter your email to receive a secure magic link
    </Card.Description>
  </Card.Header>
  <Card.Content>
    <form onsubmit={sendMagicLink}>
      <div class="grid gap-4">
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
        <Button type="submit" class="w-full" disabled={$form.processing}>
          {$form.processing ? "Sending..." : "Send Magic Link"}
        </Button>
      </div>
    </form>
    <div class="mt-4 text-center text-sm text-muted-foreground">
      We'll send you a secure link that expires in 30 minutes
    </div>
    <div class="mt-4 text-center text-sm">
      Don't have an account?
      <Link href={signupPath()} class="underline">Sign up</Link>
    </div>
  </Card.Content>
</Card.Root>
