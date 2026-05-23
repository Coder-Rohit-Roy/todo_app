<img width="1919" height="1014" alt="Screenshot 2026-05-22 123839" src="https://github.com/user-attachments/assets/7f36c8e1-4a9d-4b58-8b9e-d2063f49d3aa" />
<img width="1917" height="1023" alt="Screenshot 2026-05-22 123900" src="https://github.com/user-attachments/assets/6574ac2c-801a-470c-a2ce-2dbfaa63b032" />
# 📝 PlanIt. — Premium Glassmorphic Task Management System

PlanIt is a visually stunning, next-generation hybrid task management system. Built using a **Flutter Web Client** and powered by a secure **Node.js + Express REST API** with a **MongoDB** backend, PlanIt bridges high-fidelity UI engineering with enterprise-grade synchronization mechanics.

The interface leverages a cutting-edge **Glassmorphism visual design system** featuring real-time image blurs, harmonized gradients, tactical drag-and-drop Kanban spaces, and an adaptive offline synchronization engine that treats connectivity loss as a temporary state.

---

## 🎨 UI/UX Design System Features

*   **Glassmorphism Aesthetic:** Soft, semi-transparent card containers featuring high-density backdrop styling (`BackdropFilter` and `ImageFilter.blur`), subtle borders, and layered drop shadows.
*   **Unified Reactive Themes:** Deep indigo slate space-blue for Dark Mode, alongside crisp, muted violet-indigo hues tailored for Light Mode.
*   **Vibrant Gradient Visual Hierarchy:** Color-coded systems for rapid mental indexing:
    *   **Categories:** Work (Royal Blue ➔ Cyan), Study (Violet ➔ Magenta), Personal (Amber ➔ Red).
    *   **Priorities:** High (Crimson ➔ Coral), Medium (Amber ➔ Yellow), Low (Emerald ➔ Green).
*   **Responsive Workspace Layout:** Smooth, layout-driven transitions between a left-pinned navigation sidebar (Desktop) and an intuitive bottom tab navigation bar (Mobile/Tablet).
*   **Touch & Mouse Swipe Actions:** Swipe-right mechanics to toggle completion states; swipe-left movements to reveal destructive delete actions with sliding color backdrops.
*   **Floating Action Pill (FAB):** A glowing, anchored action pill that spawns the task creation canvas with an integrated scale and fade transition.

---

## 🏗️ Architectural Overview

The application features decoupled client-server boundaries, optimizing network transfers and enabling local runtime fallbacks.

```text
                  ┌──────────────────────────────┐
                  │      Flutter Web Client      │
                  │       (todo_frontend)        │
                  └──────────────┬───────────────┘
                                 │
                     HTTP REST   │   (If Offline: fallback to SharedPreferences)
                     API Calls   │
                                 ▼
                  ┌──────────────────────────────┐
                  │     Node.js Express API      │
                  │        (todo_backend)        │
                  └──────────────┬───────────────┘
                                 │
                        Mongoose │
                        Driver   │
                                 ▼
                  ┌──────────────────────────────┐
                  │       MongoDB Database       │
                  │          (todo_db)           │
                  └──────────────────────────────┘
