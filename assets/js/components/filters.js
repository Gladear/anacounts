document.addEventListener("filters:mounted", (event) => {
  init(event.target);
});

export function init($container) {
  $container.addEventListener("input", () => storeState($container));

  const $reset = $container.querySelector(".js-filters-reset");
  $reset.addEventListener("click", () => reset($container));

  restoreState($container);
}

function storeState($container) {
  const state = getCurrentState($container);
  localStorage.setItem(`filters-${$container.id}`, JSON.stringify(state));
}

function getCurrentState($container) {
  const filters = getFilters($container);
  let state = {};

  for (const $filter of filters) {
    const name = getName($filter);
    state[name] = getCurrentValues($filter);
  }

  return state;
}

function restoreState($container) {
  const state = getStoredState($container);
  let hasChanged = false;

  const $filters = getFilters($container);
  for (const $filter of $filters) {
    const name = getName($filter);

    if (!Object.hasOwn(state, name)) {
      continue;
    }

    const $inputs = $filter.querySelectorAll("input");
    const values = state[name];

    for (const $input of $inputs) {
      const checked = values.includes($input.value)
      hasChanged = hasChanged || $input.checked !== checked;

      $input.checked = checked;
    }
  }

  if (hasChanged) {
    submit($container);
  }
}

function getStoredState($container) {
  const raw = localStorage.getItem(`filters-${$container.id}`);
  return raw ? JSON.parse(raw) : {};
}

export function reset($container) {
  const $filters = getFilters($container);

  for (const $filter of $filters) {
    const defaultOptions = getDefaultOptions($filter);

    const $inputs = $filter.querySelectorAll("input");
    for (const $input of $inputs) {
      $input.checked = defaultOptions.includes($input.value);
    }
  }

  submit($container);
}

function getFilters($container) {
  return $container.querySelectorAll(".js-filters-filter");
}

export function submit($container) {
  // filters don't actually get submitted, they update automatically
  // when one of their inputs changes. Simulate that an input changed here.
  $container
    .querySelector("input")
    .dispatchEvent(new Event("input", { bubbles: true }));
}

// ## Filters
function getName($filter) {
  return $filter.dataset.name;
}

function getCurrentValues($filter) {
  const $inputs = $filter.querySelectorAll("input:checked");
  return Array.from($inputs).map((input) => input.value);
}

function isMultiple($filter) {
  return $filter.hasAttribute("data-multiple");
}

function getDefaultOptions($filter) {
  const defaultOptions = JSON.parse($filter.dataset.default);
  return isMultiple($filter) ? defaultOptions : [defaultOptions];
}
