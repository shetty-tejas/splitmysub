<script>
  import { Link } from "@inertiajs/svelte";
  import LoginForm from "$lib/components/login-form.svelte";
  import Logo from "$lib/components/logo.svelte";
  import AuthLayout from "../../layouts/auth-layout.svelte";
</script>

<!-- Meta tags are now handled server-side in the Rails layout for better OpenGraph support -->

<AuthLayout>
  <div class="flex flex-col h-screen w-full items-center justify-center px-4">
    <Link href="/" class="mb-8">
      <Logo class="h-8 w-48 justify-center" />
    </Link>
    <LoginForm />
  </div>
</AuthLayout>
