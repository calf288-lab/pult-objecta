import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin", "cyrillic"] });

export const metadata: Metadata = {
  title: "Пульт объекта — кабинет заказчика ремонта и стройки",
  description:
    "Заказчик видит этап, фото с объекта и деньги. Прораб кидает фото с телефона. Меньше звонков «как там?»",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="ru">
      <body className={`${inter.className} antialiased`}>{children}</body>
    </html>
  );
}
