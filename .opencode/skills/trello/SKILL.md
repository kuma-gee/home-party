---
name: trello
description: Project Trello context for Home Party task tracking. Use whenever reading, creating, updating, moving, or commenting on Trello cards for this repo. Always the "AI Tasks" board, "Home Party" list; no other boards or lists.
---

# Trello — Project Context

This project tracks work on one board and one list only.

| Item | Value |
|---|---|
| Board | `AI Tasks` |
| Board ID | `6a7d754a78e03fab7625f9bf` |
| Board nodeId (ARI) | `ari:cloud:trello::board/workspace/5e74ca75e925701a2429caeb/6a7d754a78e03fab7625f9bf` |
| List | `Home Party` |
| List ID | `6ad8bb7592105eb673ff02ab` |
| List nodeId (ARI) | `ari:cloud:trello::list/workspace/5e74ca75e925701a2429caeb/6ad8bb7592105eb673ff02ab` |

## Rules

- Always target board `AI Tasks` (`6a7d754a78e03fab7625f9bf`).
- Always target list `Home Party` (`6ad8bb7592105eb673ff02ab`).
- Never touch other boards or other lists on this board (`Planning`, `Doing`, `Pistol Shot`) unless the user explicitly names them.
- Do not call `trello_list_boards` / `trello_get_lists` to rediscover ids; use the table.
- Default the active board when operating:

  ```text
  trello_set_active_board(boardId="6a7d754a78e03fab7625f9bf")
  ```

## Common operations

- List cards in the list:

  ```text
  trello_get_cards_by_list_id(listId="6ad8bb7592105eb673ff02ab")
  ```

- Create a card:

  ```text
  trello_add_card_to_list(
    listId="6ad8bb7592105eb673ff02ab",
    name="<title>",
    description="<details>"
  )
  ```

- Create several cards in order: `trello_add_cards_to_list` with the same `listId`, cards in intended order.

- Read or update a card: take its `id` from `trello_get_cards_by_list_id`, then `trello_get_card` / `trello_update_card_details`.

- Move a card: `trello_move_card(cardId="<id>", listId="6ad8bb7592105eb673ff02ab")`.

- Comment: `trello_add_comment(cardId="<id>", text="<comment>")`.

## Labels on this board

| Label | Meaning |
|---|---|
| `Bug` | Defect fix |
| `Feature` | New functionality |
| `Refactor` | Internal cleanup |

## Id formats

The MCP tools exposed here take plain Trello object ids (the values in the table above). If a tool documents ARIs instead, use the `nodeId (ARI)` values above — never construct ids by hand.
