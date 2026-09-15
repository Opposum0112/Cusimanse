# Operation engine

The operation engine is the final CAR-controlled state boundary before adapters. It preserves `pending-approval` as a distinct state and rejects invalid lifecycle transitions.

```text
proposed → pending-approval → running → succeeded
       ↘ deny                    ↘ failed
```

The engine does not execute tools. It only validates operation lifecycle state; adapters are introduced separately.
