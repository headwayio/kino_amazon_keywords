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
  <p class="text-black py-2">Extract root words from a collection of search terms.</p>
  <div class="flex flex-col space-y-4">
    <div class="form-control">
      <label class="form-control w-full max-w-xs">
        <div class="label">
          <span class="label-text">Select Data Frame</span>
        </div>
        <select id="data-frame" class="select select-bordered">
          <option value=""></option>
        </select>
      </label>
    </div>

    <div class="form-control">
      <label class="form-control w-full max-w-xs">
        <div class="label">
          <span class="label-text">Normalize root words?</span>
        </div>
        <input id="normalize" type="checkbox" class="checkbox checkbox-bordered" />
      </label>
    </div>

    <div class="form-control">
      <label class="form-control w-full max-w-xs">
        <div class="label">
          <span class="label-text">Negative Keywords</span>
        </div>
      </label>
      <textarea id="negative-keywords" class="textarea textarea-bordered"></textarea>
    </div>

    <div class="w-32 pt-4">
      <button id="submit" class="btn btn-neutral">Submit</button>
    </div>
  </div>
</div>
  `;

  const dataFrameSelect = document.getElementById("data-frame");
  const normalizeInput = document.getElementById("normalize");
  const negativeKeywordsInput = document.getElementById("negative-keywords");
  const submitBtn = document.getElementById("submit");

  const setAvailableDataFrames = (dataFrameVariables) => {
    dataFrameSelect.innerHTML = "";

    const emptyOption = document.createElement("option");
    dataFrameSelect.add(emptyOption, null);

    Object.keys(dataFrameVariables).forEach((item) => {
      const option = document.createElement("option");

      option.value = item;
      option.text = item;

      dataFrameSelect.add(option, null);
    });
  };

  setAvailableDataFrames(payload.data_frame_variables);

  ctx.handleEvent(
    "set_available_data",
    ({ data_frame_variables, data_frame_alias, fields }) => {
      setAvailableDataFrames(data_frame_variables);
    },
  );

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
    normalizeInput.classList.remove("input-error");
    negativeKeywordsInput.classList.remove("input-error");
  };

  const initializeForm = (data) => {
    normalizeInput.setAttribute("value", data.fields.normalize || "");
    negativeKeywordsInput.value = data.fields.negative_keywords || "";
  };

  const updateNormalizeEvent = (evt) => {
    ctx.pushEvent("update_normalize", evt.target.value);
  };

  const debouncedUpdateNormalizeEvent = debounce((evt) => {
    updateNormalizeEvent(evt);
  }, 500);

  const updateNegativeKeywordsEvent = (evt) => {
    ctx.pushEvent("update_negative_keywords", evt.target.value);
  };

  const debouncedUpdateNegativeKeywordsEvent = debounce((evt) => {
    updateNegativeKeywordsEvent(evt);
  }, 500);

  const updateDataFrameEvent = (evt) => {
    ctx.pushEvent("update_data_frame", {
      field: "data_frame",
      value: evt.target.value,
    });
  };

  initializeForm(payload);

  ctx.handleEvent("update", (_data) => {
    updateFormByValidity();
  });

  dataFrameSelect.addEventListener("change", updateDataFrameEvent);
  normalizeInput.addEventListener("keyup", updateNormalizeEvent);
  negativeKeywordsInput.addEventListener("keyup", updateNegativeKeywordsEvent);
  submitBtn.addEventListener("click", () => {
    // ctx.pushEvent("submit", normalizeInput.value);
  });
}
