// Load the exact upstream font bytes before any glyphs enter egui's atlas.
async function loadEguiFonts() {
    const fonts = [
        ["EguiUbuntu", "Ubuntu-Light.ttf"],
        ["EguiHack", "Hack-Regular.ttf"],
        ["EguiIcons", "egui-icons.ttf"],
    ];
    await Promise.all(fonts.map(async ([family, file]) => {
        const response = await fetch(new URL(`fonts/${file}`, document.baseURI));
        if (!response.ok) throw new Error(`Font download failed: ${file} (${response.status})`);
        const face = new FontFace(family, await response.arrayBuffer());
        await face.load();
        document.fonts.add(face);
    }));
    await document.fonts.ready;
}
