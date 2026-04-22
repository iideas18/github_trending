# Index Search Design

## Problem

The site index currently lists daily reports, but users cannot quickly narrow the list to a specific item. As the number of reports grows, scanning the full list becomes slower and less convenient.

## Goal

Add a lightweight search experience on the index page so a user can type a term and immediately filter the visible report entries.

## Scope

In scope:

- Add a search input to `index.html`
- Filter the existing report list in the browser as the user types
- Match against the visible text already shown in each report row
- Show an empty-state message when no reports match
- Style the search UI so it fits the current visual design

Out of scope:

- Searching inside daily report pages
- Searching individual project cards across all reports
- Server-side search or any backend/index generation changes

## Chosen Approach

Use a simple client-side filter on the existing `.report-list` items.

Each report row already contains the searchable text the user cares about, such as the report date and the project count. The search logic can read each row's text content, normalize it to lowercase, and hide rows that do not include the current query.

This keeps the implementation small, avoids changing the report generation flow, and preserves the site as a fully static page.

## Alternatives Considered

### 1. Filter existing visible text

This is the selected approach. It requires the least markup and no extra data model.

### 2. Add `data-search` attributes to each list item

This would make the JavaScript slightly more explicit, but it adds markup duplication without materially improving the experience for the current page.

### 3. Build a global project-level search

This would be more powerful, but it changes the problem from "find a report" to "find any tracked project" and would require indexing data from report pages.

## UX Design

The index page gets a search section above the report list containing:

- a text input with a placeholder such as `Search reports by date or text...`
- a short helper label or hint if needed
- a hidden empty-state message directly below the report list that appears only when there are no matches
- an `aria-live` status region that announces result counts as filtering changes

Behavior:

- Filtering happens on every input event
- Search is case-insensitive
- Leading and trailing whitespace is ignored
- Clearing the input restores the full list
- If no items match, hide all list items and show the empty-state message
- The stats bar remains static and continues to show overall site totals instead of filtered totals

## Implementation Notes

### HTML

Add a search container between the stats bar and the report list.

Expected elements:

- search wrapper
- text input with an accessible label
- live-status element for announcing result counts
- empty-state element below the list

### JavaScript

Add a small inline script at the bottom of `index.html` that:

1. selects the search input
2. selects all report list items
3. listens for `input`
4. compares the normalized query with each item's text content
5. hides non-matching items using a dedicated CSS class that applies `display: none`
6. toggles the empty-state message
7. updates the live-status region with messages such as `9 results`, `1 result`, or `No results`

### CSS

Add styles in `style.css` for:

- search wrapper
- search input
- input focus state
- empty-state message
- hidden-item state used by search filtering
- live-status text

The styles should reuse the current dark theme variables and spacing patterns so the new UI looks native to the existing page.

## Error Handling

- If the script fails to run, the full list remains visible, so the page still works
- An empty query is treated as "show everything"
- No special parsing is needed; all matching is substring-based
- Result-count changes are announced through the live region for assistive technology users

## Testing

Validate the following manually:

- typing a full date filters to the matching report
- typing a partial date filters correctly
- typing `projects` still shows rows because that text exists in each entry
- typing a nonsense query shows the empty state
- clearing the input restores all rows
- screen readers receive result-count updates through the live region
- the layout remains readable on smaller screens

## Expected Outcome

Users can quickly narrow the index page to the report they want without changing the report generation pipeline or adding any backend logic.
