import { createHashRouter as createBrowserRouter } from "react-router";
import Root from "./components/Root";
import HomePage from "./components/Home";
import SchedulePage from "./components/Schedule";
import NotificationPage from "./components/Notification";
import ProfilePage from "./components/Profile";

export const router = createBrowserRouter([
  {
    path: "/",
    Component: Root,
    children: [
      { index: true, Component: HomePage },
      { path: "schedule", Component: SchedulePage },
      { path: "notification", Component: NotificationPage },
      { path: "profile", Component: ProfilePage },
    ],
  },
]);
