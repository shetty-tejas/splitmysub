<script>
  import { createEventDispatcher } from "svelte";

  export let value = "";
  export let onValueChange = null;

  const dispatch = createEventDispatcher();

  let isOpen = false;
  let selectedValue = value;

  function handleSelect(newValue) {
    selectedValue = newValue;
    value = newValue;
    isOpen = false;

    if (onValueChange) {
      onValueChange(newValue);
    }

    dispatch("change", newValue);
  }

  function toggleOpen() {
    isOpen = !isOpen;
  }

  function closeSelect() {
    isOpen = false;
  }

  $: value = selectedValue;
</script>

<div class="relative">
  <slot {selectedValue} {isOpen} {toggleOpen} {handleSelect} {closeSelect} />
</div>
