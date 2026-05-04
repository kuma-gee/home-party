export const ICONS: Record<string, string> = {
    "paw": "e91d",
    "rabbit": "e799",
    "raven": "f555",
    "horse": "f25e",
    "owl": "f3b4",
    "bone": "efb1",
    "crossaint": "ea53",
    "pizza": "e552",
    "star": "e838",
    "heart": "e87d",
    "moon": "f34f",
}

export function getIconForPlayer(playerNumber: number): string {
    const iconKeys = Object.keys(ICONS);
    const idx = playerNumber % iconKeys.length;
    return ICONS[iconKeys[idx]];
}