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
<div class="bg-white px-4">
  <p class="text-black mb-2">Fetch related keywords by entering a base keyword below.</p>
  <div class="flex flex-col space-y-4">
    <label class="form-control w-full max-w-xs">
      <div class="label">
        <span class="label-text">Keyword</span>
      </div>
      <input id="keyword" type="text" placeholder="Type here" class="input input-bordered w-full max-w-xs" />
    </label>
    <div class="w-16">
      <button id="submit" class="btn">Submit</button>
    </div>
  </div>
</div>
  `;

  const keywordInput = document.getElementById("keyword");
  const submit = document.getElementById("submit");

  ctx.handleEvent("update", (data) => {
    if (!data.keyword) {
      submit.setAttribute("disabled", "true");
      submit.classList.add("disabled");
    } else {
      submit.removeAttribute("disabled");
      submit.classList.remove("disabled");
    }
  });

  keywordInput.addEventListener("keyup", (evt) => {
    ctx.pushEvent("update_keyword", evt.currentTarget.value);
  });

  submit.addEventListener("click", () => {
    ctx.pushEvent("submit", "");
  });
}
