<script>
  import { createEventDispatcher } from "svelte";

  export let checked = false;
  export let disabled = false;
  export let id = undefined;
  export let name = undefined;
  export let value = undefined;

  const dispatch = createEventDispatcher();

  function handleChange(event) {
    checked = event.target.checked;
    dispatch("change", { checked, value });
  }
</script>

<input
  type="checkbox"
  {id}
  {name}
  {value}
  {checked}
  {disabled}
  onchange={handleChange}
  class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 focus:ring-2 focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed"
  {...$$restProps}
/>
