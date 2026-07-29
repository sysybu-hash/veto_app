/**
 * Barrel for the VETO UI kit. Import primitives and the pre-existing
 * shared components from here: `import { Button, Card, EmptyState } from "@/components/ui"`.
 */

// Phase 2 primitives
export { Button, type ButtonProps } from "./primitives/Button";
export { IconButton, type IconButtonProps } from "./primitives/IconButton";
export { Input, Textarea, Select, type InputProps, type TextareaProps, type SelectProps } from "./primitives/Input";
export { Field, type FieldProps } from "./primitives/Field";
export { Card, type CardProps } from "./primitives/Card";
export { Modal, type ModalProps } from "./primitives/Modal";
export { Table, type TableProps } from "./primitives/Table";
export { Badge, type BadgeProps } from "./primitives/Badge";
export { Tabs, type TabsProps, type TabItem } from "./primitives/Tabs";
export { ButtonGroup, type ButtonGroupProps } from "./primitives/ButtonGroup";

// Pre-existing shared components
export { Skeleton, SkeletonText, SkeletonCard } from "./Skeleton";
export { EmptyState } from "./EmptyState";
export { ToastHost } from "./ToastHost";
export { ThemeToggle } from "./ThemeToggle";
