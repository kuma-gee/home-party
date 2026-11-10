---
name: trello
description: Project Trello context for Home Party task tracking. Use whenever reading, creating, updating, moving, or commenting on Trello cards for this repo. Always the "Home Party" board and its lists (General plus one per mini-game); no other boards or lists.
---

# Trello — Project Context

This project tracks work on one board only: **Home Party**. Each mini-game has its own list on that board, plus a `General` list for general tasks.

| Item | Value |
|---|---|
| Board | `Home Party` |
| Board ID | `6af325028e7e18148e462097` |
| Board nodeId (ARI) | `ari:cloud:trello::board/workspace/5e74ca75e925701a2429caeb/6af325028e7e18148e462097` |

## Lists on the board

| List | Purpose | List ID |
|---|---|---|
| `General` | General tasks not tied to a mini-game | `6af325038e7e18148e4620ad` |
| `Castle Defense` | Castle Defense mini-game | `6af3261158faf6ac6b06c2ef` |
| `Vortex Volley` | Vortex Volley mini-game | `6ad8bb7592105eb673ff02ab` |
| `Ghost Hunter` | Ghost Hunter mini-game | `6aea06727438071937378aee` |

List ARIs follow the standard shape `ari:cloud:trello::list/workspace/5e74ca75e925701a2429caeb/<listId>`.

## Rules

- Always target board `Home Party` (`6af325028e7e18148e462097`).
- Target the list matching the mini-game the card is about; use `General` (`6af325038e7e18148e4620ad`) when no mini-game is involved or the user doesn't specify one. When in doubt, ask.
- Never touch other boards or lists outside this board's table unless the user explicitly names them.
- Do not call `trello_list_boards` / `trello_get_lists` to rediscover ids; use the tables.
- Default the active board when operating:

  ```text
  trello_set_active_board(boardId="6af325028e7e18148e462097")
  ```

## Common operations

- List cards in a list (use the list ID from the table):

  ```text
  trello_get_cards_by_list_id(listId="6af325038e7e18148e4620ad")
  ```

- Create a card in a list:

  ```text
  trello_add_card_to_list(
    listId="<listId from table>",
    name="<title>",
    description="<details>"
  )
  ```

- Create several cards in order: `trello_add_cards_to_list` with the same `listId`, cards in intended order.

- Read or update a card: take its `id` from `trello_get_cards_by_list_id`, then `trello_get_card` / `trello_update_card_details`.

- Move a card (e.g. between mini-game lists or to `General`): `trello_move_card(cardId="<id>", listId="<listId from table>")`.

- Comment: `trello_add_comment(cardId="<id>", text="<comment>")`.

## Id formats

The MCP tools exposed here take plain Trello object ids (the values in the tables above). If a tool documents ARIs instead, use the `nodeId (ARI)` values above or the documented list ARI shape — never construct ids by hand.
