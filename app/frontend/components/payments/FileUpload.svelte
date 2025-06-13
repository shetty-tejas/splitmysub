<script>
  import { createEventDispatcher } from "svelte";

  export let accept =
    "image/png,image/jpg,image/jpeg,image/heic,application/pdf";
  export let maxSize = 5 * 1024 * 1024; // 5MB
  export let file = null;
  export let error = "";
  export let disabled = false;

  const dispatch = createEventDispatcher();

  let dragOver = false;
  let fileInput;

  const allowedTypes = [
    "image/png",
    "image/jpg",
    "image/jpeg",
    "image/heic",
    "application/pdf",
  ];

  function handleDragOver(event) {
    event.preventDefault();
    if (!disabled) {
      dragOver = true;
    }
  }

  function handleDragLeave(event) {
    event.preventDefault();
    dragOver = false;
  }

  function handleDrop(event) {
    event.preventDefault();
    dragOver = false;

    if (disabled) return;

    const files = event.dataTransfer.files;
    if (files.length > 0) {
      handleFileSelection(files[0]);
    }
  }

  function handleFileInput(event) {
    const files = event.target.files;
    if (files.length > 0) {
      handleFileSelection(files[0]);
    }
  }

  function handleFileSelection(selectedFile) {
    error = "";

    // Validate file type
    if (!allowedTypes.includes(selectedFile.type)) {
      error = "Please select a PNG, JPG, HEIC, or PDF file.";
      return;
    }

    // Validate file size
    if (selectedFile.size > maxSize) {
      error = "File size must be less than 5MB.";
      return;
    }

    file = selectedFile;
    dispatch("fileSelected", { file: selectedFile });
  }

  function removeFile() {
    file = null;
    error = "";
    if (fileInput) {
      fileInput.value = "";
    }
    dispatch("fileRemoved");
  }

  function formatFileSize(bytes) {
    if (bytes === 0) return "0 Bytes";
    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  }

  function getFileIcon(type) {
    if (type.startsWith("image/")) {
      return "🖼️";
    } else if (type === "application/pdf") {
      return "📄";
    }
    return "📎";
  }
</script>

<div class="file-upload-container">
  {#if !file}
    <div
      class="upload-area {dragOver ? 'drag-over' : ''} {disabled
        ? 'disabled'
        : ''}"
      on:dragover={handleDragOver}
      on:dragleave={handleDragLeave}
      on:drop={handleDrop}
      role="button"
      tabindex="0"
      on:click={() => !disabled && fileInput.click()}
      on:keydown={(e) =>
        (e.key === "Enter" || e.key === " ") && !disabled && fileInput.click()}
    >
      <div class="upload-content">
        <div class="upload-icon">📁</div>
        <p class="upload-text">
          <strong>Click to upload</strong> or drag and drop
        </p>
        <p class="upload-subtext">PNG, JPG, HEIC, or PDF (max 5MB)</p>
      </div>
    </div>
  {:else}
    <div class="file-preview">
      <div class="file-info">
        <div class="file-icon">{getFileIcon(file.type)}</div>
        <div class="file-details">
          <p class="file-name">{file.name}</p>
          <p class="file-size">{formatFileSize(file.size)}</p>
        </div>
        <button
          type="button"
          class="remove-button"
          on:click={removeFile}
          {disabled}
        >
          ✕
        </button>
      </div>

      {#if file.type.startsWith("image/")}
        <div class="image-preview">
          <img src={URL.createObjectURL(file)} alt="Preview" />
        </div>
      {/if}
    </div>
  {/if}

  {#if error}
    <div class="error-message">
      {error}
    </div>
  {/if}

  <input
    bind:this={fileInput}
    type="file"
    {accept}
    on:change={handleFileInput}
    style="display: none;"
    {disabled}
  />
</div>

<style>
  .file-upload-container {
    width: 100%;
  }

  .upload-area {
    border: 2px dashed #d1d5db;
    border-radius: 8px;
    padding: 2rem;
    text-align: center;
    cursor: pointer;
    transition: all 0.2s ease;
    background-color: #f9fafb;
  }

  .upload-area:hover:not(.disabled) {
    border-color: #3b82f6;
    background-color: #eff6ff;
  }

  .upload-area.drag-over {
    border-color: #3b82f6;
    background-color: #eff6ff;
    transform: scale(1.02);
  }

  .upload-area.disabled {
    opacity: 0.5;
    cursor: not-allowed;
    background-color: #f3f4f6;
  }

  .upload-content {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
  }

  .upload-icon {
    font-size: 2rem;
    margin-bottom: 0.5rem;
  }

  .upload-text {
    margin: 0;
    font-size: 1rem;
    color: #374151;
  }

  .upload-subtext {
    margin: 0;
    font-size: 0.875rem;
    color: #6b7280;
  }

  .file-preview {
    border: 1px solid #d1d5db;
    border-radius: 8px;
    padding: 1rem;
    background-color: #f9fafb;
  }

  .file-info {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .file-icon {
    font-size: 1.5rem;
  }

  .file-details {
    flex: 1;
  }

  .file-name {
    margin: 0;
    font-weight: 500;
    color: #374151;
    word-break: break-all;
  }

  .file-size {
    margin: 0;
    font-size: 0.875rem;
    color: #6b7280;
  }

  .remove-button {
    background: #ef4444;
    color: white;
    border: none;
    border-radius: 50%;
    width: 24px;
    height: 24px;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 0.75rem;
    transition: background-color 0.2s ease;
  }

  .remove-button:hover:not(:disabled) {
    background: #dc2626;
  }

  .remove-button:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .image-preview {
    border-top: 1px solid #e5e7eb;
    padding-top: 1rem;
  }

  .image-preview img {
    max-width: 100%;
    max-height: 200px;
    border-radius: 4px;
    object-fit: contain;
  }

  .error-message {
    margin-top: 0.5rem;
    padding: 0.5rem;
    background-color: #fef2f2;
    border: 1px solid #fecaca;
    border-radius: 4px;
    color: #dc2626;
    font-size: 0.875rem;
  }
</style>
