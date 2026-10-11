import type { MetadataRoute } from "next";

type BoralogManifest = MetadataRoute.Manifest & {
  share_target: {
    action: string;
    method: "POST";
    enctype: "application/x-www-form-urlencoded";
    params: { title: string; text: string; url: string };
  };
};

export default function manifest(): BoralogManifest {
  return {
    name: "BORALOG",
    short_name: "BORALOG",
    description: "La mémoire opérationnelle partagée du spectacle vivant.",
    start_url: "/",
    scope: "/",
    display: "standalone",
    background_color: "#f4efe5",
    theme_color: "#1f1f1d",
    icons: [
      { src: "/boralog-192.png", sizes: "192x192", type: "image/png" },
      { src: "/boralog-512.png", sizes: "512x512", type: "image/png" },
    ],
    share_target: {
      action: "/partager/android",
      method: "POST",
      enctype: "application/x-www-form-urlencoded",
      params: { title: "title", text: "text", url: "url" },
    },
  };
}
