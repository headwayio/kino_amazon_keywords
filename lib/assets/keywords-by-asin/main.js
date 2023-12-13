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
  <p class="text-black py-2">Fetch related keywords by entering a target ASIN and one or more competitor ASIN's (comma seperated).</p>
  <div class="flex flex-col space-y-4">
    <div class="form-control">
      <label class="form-control w-full max-w-xs">
        <div class="label">
          <span class="label-text">ASIN</span>
        </div>
        <input id="asin" type="text" placeholder="Enter target ASIN" class="input input-bordered w-full max-w-xs" />
      </label>
    </div>

    <div class="form-control">
      <label class="form-control w-full max-w-xs">
        <div class="label">
          <span class="label-text">Competitor ASIN's</span>
        </div>
      </label>
      <textarea id="competitors" placeholder="Enter competitor ASIN's" class="textarea textarea-bordered"></textarea>
    </div>

    <div class="w-32 pt-4">
      <button id="submit" class="btn btn-neutral">Submit</button>
    </div>
  </div>
</div>
  `;

  const asinInput = document.getElementById("asin");
  const competitorsInput = document.getElementById("competitors");
  const submitBtn = document.getElementById("submit");

  const debounce = (func, interval) => {
    let timeoutId;

    return (...args) => {
      clearTimeout(timeoutId);

      timeoutId = setTimeout(() => {
        func.apply(this, args);
      }, interval);
    };
  };

  const updateFormByValidity = () => {
    asinInput.classList.remove("input-error");
    competitorsInput.classList.remove("input-error");

    if (!isAsinValid(asinInput.value)) {
      asinInput.classList.add("input-error");
    }
  };

  const isAsinValid = (asin) => {
    return asin.match(/[^A-Za-z0-9]/g) || asin === "";
  };

  const initializeForm = (data) => {
    asinInput.setAttribute("value", data.fields.asin || "");
    competitorsInput.value = data.fields.competitors || "";

    // updateFormByValidity(data.fields.asin);
  };

  const updateASINEvent = (evt) => {
    ctx.pushEvent("update_asin", evt.target.value);
  };

  const debouncedUpdateASINEvent = debounce((evt) => {
    updateASINEvent(evt);
  }, 500);

  const updateCompetitorsEvent = (evt) => {
    ctx.pushEvent("update_competitors", evt.target.value);
  };

  const debouncedUpdateCompetitorsEvent = debounce((evt) => {
    updateCompetitorsEvent(evt);
  }, 500);

  initializeForm(payload);

  ctx.handleEvent("update", (_data) => {
    updateFormByValidity();
  });

  asinInput.addEventListener("keyup", updateASINEvent);
  competitorsInput.addEventListener("keyup", updateCompetitorsEvent);
  submitBtn.addEventListener("click", () => {
    // ctx.pushEvent("submit", asinInput.value);
  });
}
