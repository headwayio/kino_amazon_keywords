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
  <p class="text-black py-2">Fetch related keywords by entering a base keyword below.</p>
  <div class="flex flex-col space-y-4">
    <div class="form-control">
      <label class="form-control w-full max-w-xs">
        <div class="label">
          <span class="label-text">Keyword</span>
        </div>
        <input id="keyword" type="text" placeholder="Enter base keyword here" class="input input-bordered w-full max-w-xs" />
      </label>
    </div>

    <div class="form-control">
      <label class="cursor-pointer label justify-start">
        <span class="label-text mr-4">Generate variants?</span>
        <input id="variants" type="checkbox" class="checkbox checkbox-accent" />
      </label>
    </div>
  </div>
</div>
  `;

  const keywordInput = document.getElementById("keyword");
  const variantsInput = document.getElementById("variants");

  const debounce = (func, interval) => {
    let timeoutId;

    return (...args) => {
      clearTimeout(timeoutId);

      timeoutId = setTimeout(() => {
        func.apply(this, args);
      }, interval);
    };
  };

  const initializeForm = (data) => {
    keywordInput.setAttribute("value", data.fields.keyword || "");
    variantsInput.checked = data.fields.variants;

    updateFormByValidity(data.fields.keyword);
  };

  const updateFormByValidity = (keyword) => {};

  const debouncedUpdateKeywordEvent = debounce((evt) => {
    ctx.pushEvent("update_keyword", evt.target.value);
  }, 500);

  initializeForm(payload);

  ctx.handleEvent("update", (data) => {
    updateFormByValidity(data.keyword);
  });

  keywordInput.addEventListener("keyup", debouncedUpdateKeywordEvent);
  variantsInput.addEventListener("change", (evt) => {
    ctx.pushEvent("update_variants", evt.target.checked);
  });
}
