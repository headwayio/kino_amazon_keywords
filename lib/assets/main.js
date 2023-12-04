export async function init(ctx, payload) {
  ctx.importCSS("https://cdn.jsdelivr.net/npm/daisyui@2.6.0/dist/full.css");
  ctx.importJS("https://cdn.tailwindcss.com").then(() => {
    tailwind.config = {
      theme: {
        extend: {
          colors: {},
        },
      },
    };
  });

  ctx.importCSS("main.css");

  ctx.root.innerHTML = `
<div class="flex flex-col bg-white p-4 space-y-4">
  <label class="form-control w-full max-w-xs">
    <div class="label">
      <span class="label-text">Base Keyword</span>
    </div>
    <input id="keyword" type="text" placeholder="Type here" class="input input-bordered w-full max-w-xs" />
    <div class="label">
      <span class="label-text-alt">Bottom Left label</span>
      <span class="label-text-alt">Bottom Right label</span>
    </div>
  </label>
  <div class="w-16">
    <button id="submit" class="btn">Submit</button>
  </div>
</div>
  `;

  const keywordInput = document.getElementById("keyword");
  const submit = document.getElementById("submit");

  keywordInput.addEventListener("change", (evt) => {
    ctx.pushEvent("update_keyword", evt.target.value);
  });

  submit.addEventListener("click", () => {
    ctx.pushEvent("submit", "");
  });
}
